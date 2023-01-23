terraform {
  backend "s3" {
    bucket = "gitlab-tf"
    key    = "gitlab/terraform.tfstate"
    region = "ap-south-1"
  }
}
