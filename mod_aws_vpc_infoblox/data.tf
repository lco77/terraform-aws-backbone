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
