terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
      configuration_aliases = [ aws.tgw , aws.vpc , aws.r53 , aws.ssm ]
    }
  }
}