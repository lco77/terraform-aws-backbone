# caution: instance type in locals.tf must match architecture filter
data "aws_ami" "amazon-linux-2" {
  provider    = aws.vpc
  most_recent = true
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name   = "name"
    values = ["amzn2-ami-*-hvm-*-arm64-gp2"]
  }
  filter {
    name = "architecture"
    values = ["arm64"]
  }
}

################################################################################
# Supporting Resources for DynamoDB endpoints
################################################################################

data "aws_security_group" "default" {
  count    = (local.create_private_subnets || local.create_public_subnets) && (var.vpc.private.vpce_dynamodb || var.vpc.public.vpce_dynamodb) ? 1 : 0
  provider = aws.vpc
  name   = "default"
  vpc_id = aws_vpc.this[0].id
}

# Data source used to avoid race condition
data "aws_vpc_endpoint_service" "dynamodb" {
  count    = (local.create_private_subnets || local.create_public_subnets) && (var.vpc.private.vpce_dynamodb || var.vpc.public.vpce_dynamodb) ? 1 : 0
  provider = aws.vpc
  service = "dynamodb"

  filter {
    name   = "service-type"
    values = ["Gateway"]
  }
}

data "aws_iam_policy_document" "dynamodb_endpoint_policy" {
  count    = (local.create_private_subnets || local.create_public_subnets) && (var.vpc.private.vpce_dynamodb || var.vpc.public.vpce_dynamodb) ? 1 : 0
  provider = aws.vpc
  statement {
    effect    = "Deny"
    actions   = ["dynamodb:*"]
    resources = ["*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "aws:sourceVpce"

      values = [data.aws_vpc_endpoint_service.dynamodb[0].id]
    }
  }
}

data "aws_iam_policy_document" "generic_endpoint_policy" {
  count    = (local.create_private_subnets || local.create_public_subnets) && (var.vpc.private.vpce_dynamodb || var.vpc.public.vpce_dynamodb) ? 1 : 0
  provider = aws.vpc
  statement {
    effect    = "Deny"
    actions   = ["*"]
    resources = ["*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "aws:sourceVpce"

      values = [data.aws_vpc_endpoint_service.dynamodb[0].id]
    }
  }
}