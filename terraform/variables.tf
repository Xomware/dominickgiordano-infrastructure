variable "app_name" {
  description = "Name used for roles, tags and the Infisical folder."
  type        = string
  default     = "dominickgiordano"
}

variable "domain_name" {
  description = "Apex domain. Also the S3 bucket name and the Route53 hosted zone."
  type        = string
  default     = "dominickgiordano.com"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "default_branch" {
  description = "Branch a push to which may run terraform apply."
  type        = string
  default     = "master"
}

# Read these off the repo, never build them from a name:
#   gh api /repos/Xomware/<repo>/actions/oidc/customization/sub -q .sub_claim_prefix
# Both spellings are listed so a rename or a flip back to name-based subjects keeps working.
variable "github_frontend_subjects" {
  description = "OIDC subject prefixes allowed to assume the frontend deploy role."
  type        = list(string)
  default = [
    "repo:Xomware/dominickgiordano-frontend",
    "repo:Xomware@263047999/dominickgiordano-frontend@1455706126",
  ]
}

variable "github_infrastructure_subjects" {
  description = "OIDC subject prefixes for this infrastructure repository."
  type        = list(string)
  default = [
    "repo:Xomware/dominickgiordano-infrastructure",
    "repo:Xomware@263047999/dominickgiordano-infrastructure@1455719693",
  ]
}
