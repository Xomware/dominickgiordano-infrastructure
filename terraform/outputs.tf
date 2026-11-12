# These three go into Infisical /dominickgiordano as AWS_FRONTEND_ROLE_ARN, AWS_TERRAFORM_PLAN_ROLE_ARN and
# AWS_TERRAFORM_APPLY_ROLE_ARN, the names the shared Xomware workflows read.

output "frontend_role_arn" {
  value = aws_iam_role.frontend.arn
}

output "terraform_plan_role_arn" {
  value = aws_iam_role.terraform_plan.arn
}

output "terraform_apply_role_arn" {
  value = aws_iam_role.terraform_apply.arn
}

output "cloudfront_domain_name" {
  value = module.web.cloudfront_domain_name
}
