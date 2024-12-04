terraform {
  cloud {
    organization = "fsouza"

    workspaces {
      name = "aws-fsouza-sandbox"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  profile = "fsouza-sandbox"
}
