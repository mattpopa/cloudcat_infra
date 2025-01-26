terraform {
  required_version = "1.10.4"

  backend "s3" {
    bucket = "cloudcat-tf-state"
    key    = "cloudcat-digital/hosting.tfstate"
    region = "eu-central-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.70.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

provider "aws" {
  alias  = "use1"
  region = "us-east-1"
}