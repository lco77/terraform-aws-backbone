resource "aws_ec2_transit_gateway_peering_attachment" "this" {
  for_each  = {
    for peer in var.transit_attach[var.tgw]: peer => {
      tgw_id           = var.transit_gateways[var.tgw].tgw_id
      peer_tgw_id      = var.transit_gateways[peer].tgw_id
      peer_region_code = peer
      peer_region_name = lookup(var.map_code_to_region,peer,"")
    }
  }
  peer_region             = each.value.peer_region_name
  peer_transit_gateway_id = each.value.peer_tgw_id
  transit_gateway_id      = each.value.tgw_id
  tags                    = merge(var.tags, {Name = "${var.resource_prefixes.aws_ec2_transit_gateway_peering_attachment}-${each.value.peer_region_code}"})
}
