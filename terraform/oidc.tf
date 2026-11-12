# Account-wide provider, created by whichever Xomware stack migrated to OIDC first.
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

#**********************
# Frontend deploy role: sync the bucket and invalidate the distribution, nothing else
#**********************

data "aws_iam_policy_document" "frontend_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Any ref: the deploy also runs from workflow_dispatch on other refs.
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [for s in var.github_frontend_subjects : "${s}:*"]
    }
  }
}

resource "aws_iam_role" "frontend" {
  name               = "${var.app_name}-github-actions-frontend"
  assume_role_policy = data.aws_iam_policy_document.frontend_trust.json
  tags               = local.standard_tags
}

data "aws_iam_policy_document" "frontend" {
  statement {
    sid       = "PublishSite"
    effect    = "Allow"
    actions   = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject", "s3:ListBucket"]
    resources = [module.web.s3_bucket_arn, "${module.web.s3_bucket_arn}/*"]
  }

  # The shared deploy finds its distribution by alias, and ListDistributions has no resource form.
  statement {
    sid       = "FindDistribution"
    effect    = "Allow"
    actions   = ["cloudfront:ListDistributions"]
    resources = ["*"]
  }

  statement {
    sid       = "InvalidateCache"
    effect    = "Allow"
    actions   = ["cloudfront:CreateInvalidation", "cloudfront:GetInvalidation"]
    resources = [module.web.cloudfront_distribution_arn]
  }
}

resource "aws_iam_role_policy" "frontend" {
  name   = "deploy"
  role   = aws_iam_role.frontend.id
  policy = data.aws_iam_policy_document.frontend.json
}

#**********************
# Terraform roles for this repo's workflow. Same split as the other Xomware stacks:
# plan is read-only from any ref (PR plans work), apply is admin and only from a push to master.
#**********************

data "aws_iam_policy_document" "terraform_plan_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [for s in var.github_infrastructure_subjects : "${s}:*"]
    }
  }
}

data "aws_iam_policy_document" "terraform_apply_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Default branch only, not `:*`, so nothing that can open a pull request can apply.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [for s in var.github_infrastructure_subjects : "${s}:ref:refs/heads/${var.default_branch}"]
    }
  }
}

resource "aws_iam_role" "terraform_plan" {
  name               = "${var.app_name}-github-actions-terraform-plan"
  assume_role_policy = data.aws_iam_policy_document.terraform_plan_trust.json
  tags               = local.standard_tags
}

resource "aws_iam_role" "terraform_apply" {
  name               = "${var.app_name}-github-actions-terraform-apply"
  assume_role_policy = data.aws_iam_policy_document.terraform_apply_trust.json
  tags               = local.standard_tags
}

resource "aws_iam_role_policy_attachment" "terraform_plan" {
  role       = aws_iam_role.terraform_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "terraform_apply" {
  role       = aws_iam_role.terraform_apply.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Admin minus the one move that turns an hour-long token into a permanent credential.
data "aws_iam_policy_document" "terraform_apply_guardrails" {
  statement {
    sid    = "NoPersistentCredentials"
    effect = "Deny"
    actions = [
      "iam:CreateUser",
      "iam:CreateAccessKey",
      "iam:UpdateAccessKey",
      "iam:CreateLoginProfile",
      "iam:UpdateLoginProfile",
      "iam:CreateSAMLProvider",
      "iam:UpdateSAMLProvider",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "terraform_apply_guardrails" {
  name   = "guardrails"
  role   = aws_iam_role.terraform_apply.id
  policy = data.aws_iam_policy_document.terraform_apply_guardrails.json
}

# A plan takes the state lock, and ReadOnlyAccess cannot write DynamoDB.
data "aws_iam_policy_document" "terraform_plan_state_lock" {
  statement {
    sid       = "StateLock"
    effect    = "Allow"
    actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"]
    resources = ["arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/xomware-terraform-locks"]
  }
}

resource "aws_iam_role_policy" "terraform_plan_state_lock" {
  name   = "state-lock"
  role   = aws_iam_role.terraform_plan.id
  policy = data.aws_iam_policy_document.terraform_plan_state_lock.json
}
