terraform {
  required_version = "~> 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.49.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.1"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.3.0"
    }
    template = {
      source  = "hashicorp/template"
      version = ">= 2.2.0"
    }
  }
}
