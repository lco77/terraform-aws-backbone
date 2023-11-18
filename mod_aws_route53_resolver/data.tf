# get private subnets
data "aws_subnet" "private_subnets" {
  count      = length(local.private_subnet_ids)
  id         = local.private_subnet_ids[count.index]
}



