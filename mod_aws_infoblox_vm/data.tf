# get private subnets
data "aws_subnet" "private_subnets" {
  count      = length(local.private_subnet_ids)
  id         = local.private_subnet_ids[count.index]
}

# Get AMI
data "aws_ami" "this" {
  most_recent = true
  dynamic "filter" {
    for_each = var.appliance.ami_filter
    content {
        name = filter.key
        values = filter.value
    }
  }
}

# Get Random ID
resource "random_id" "this" {
  byte_length  = 4
}