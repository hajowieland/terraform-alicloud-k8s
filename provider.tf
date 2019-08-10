provider "alicloud" {
  version    = ">=1.53.0"
  access_key = var.ali_access_key
  secret_key = var.ali_secret_key
  region     = var.ali_region
}
