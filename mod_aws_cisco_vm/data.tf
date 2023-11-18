# Get default KMS key
data "aws_ebs_default_kms_key" "current" {
}
data "aws_kms_alias" "current_arn" {
  name  = data.aws_ebs_default_kms_key.current.key_arn
}

# Get AMI
data "aws_ami" "this" {
  most_recent = true
  dynamic "filter" {
    for_each = local.appliance.ami_filter
    content {
        name = filter.key
        values = filter.value
    }
  }
}
