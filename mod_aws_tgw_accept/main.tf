resource "aws_ec2_transit_gateway_peering_attachment_accepter" "this" {
  for_each                      = {
    for src in var.transit_accept[var.tgw]: src => {
      id          = var.transit_attachments[src][var.tgw].id
      region      = var.transit_attachments[src][var.tgw].region
    }
  }
  transit_gateway_attachment_id = each.value.id
  # Note that we add "SourceRegion" tag which is used in output.tf
  tags                          = merge(var.tags, {Name = "${var.resource_prefixes.aws_ec2_transit_gateway_peering_attachment_accepter}-${each.value.region}", SourceRegion = var.transit_attachments[each.value.region][var.tgw].region })
}