# The zone is created by registering the domain in Route53, not by this stack.
data "aws_route53_zone" "site" {
  name         = var.domain_name
  private_zone = false
}

data "aws_ssm_parameter" "shared_cloudfront_waf_arn" {
  name = "/xomware/shared/cloudfront-waf-acl-arn"
}

module "web" {
  source = "git::https://github.com/domgiordano/web-hosting.git?ref=v1.8.0"

  app_name    = var.app_name
  domain_name = var.domain_name
  zone_id     = data.aws_route53_zone.site.zone_id
  tags        = local.standard_tags

  # www gets a cert entry and a DNS record, then a 301 to the apex.
  subject_alternative_names = ["www.${var.domain_name}"]
  canonical_host            = var.domain_name

  waf_acl_arn    = data.aws_ssm_parameter.shared_cloudfront_waf_arn.value
  spa_error_path = "/index.html"

  # Recruiters and link-preview crawlers can be anywhere, unlike the app sites.
  geo_restriction_locations = []
}
