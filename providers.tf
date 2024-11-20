terraform {
  required_version = ">= 1.1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.34.0"
      configuration_aliases = [
        aws.aws-intermediate,
        aws.aws-source,
      ]
    }
  }
}
