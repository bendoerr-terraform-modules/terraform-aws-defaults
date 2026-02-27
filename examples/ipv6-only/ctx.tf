module "context" {
  source  = "bendoerr-terraform-modules/context/null"
  version = "0.5.0"

  namespace      = var.namespace
  environment    = var.environment
  role           = var.role
  role_short     = var.role_short
  region         = var.region
  region_short   = var.region_short
  instance       = var.instance
  instance_short = var.instance_short
  attributes     = var.attributes
  tags           = var.tags
  context        = var.context
  project        = var.project
}
