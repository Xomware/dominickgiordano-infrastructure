# dominickgiordano-infrastructure

Terraform for [dominickgiordano.com](https://dominickgiordano.com): S3 + CloudFront + ACM + Route53 via the
`web-hosting` module (www redirects to the apex), plus the GitHub OIDC roles the frontend deploy and this repo's
Terraform workflow assume.

## One-time bootstrap

The Terraform workflow assumes roles this stack creates, so the first apply can't run in CI.

1. Register `dominickgiordano.com` in Route53. That creates the hosted zone `web_hosting.tf` looks up.
2. Run the first apply with admin credentials:
   ```bash
   cd terraform
   terraform init
   terraform apply
   ```
3. Put the outputs into Infisical folder `/dominickgiordano`:

   | Infisical secret | `terraform output` |
   |---|---|
   | `AWS_FRONTEND_ROLE_ARN` | `frontend_role_arn` |
   | `AWS_TERRAFORM_PLAN_ROLE_ARN` | `terraform_plan_role_arn` |
   | `AWS_TERRAFORM_APPLY_ROLE_ARN` | `terraform_apply_role_arn` |

After that, pull requests get a plan and a push to `master` applies.
