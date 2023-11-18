resource "aws_route53_zone" "this" {
  for_each  = { for i,v in local.zones: v => v }
  name      = each.value
  dynamic "vpc" {
    for_each = local.vpcs
    content {
      vpc_id     = vpc.value.id
      vpc_region = local.map_code_to_region[vpc.value.region]
    }
  }
  # Prevent the deletion of associated VPCs after the initial creation.
  lifecycle {
    ignore_changes = [vpc]
  }
}
