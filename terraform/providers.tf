provider "aws" {
  region = var.region
  #access_key from AWS_ACCESS_KEY_ID
  #secret_key from AWS_SECRET_ACCESS_KEY
  default_tags {
    tags = merge(var.common_tags, {
      Terraform   = true
      Environment = "poc"
    })
  }
}
