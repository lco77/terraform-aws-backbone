
# Create TGW routing tables
resource "aws_ec2_transit_gateway_route_table" "this" {
  for_each           = { for i,v in local.tgw.transit_tables: v => v}
  transit_gateway_id = local.tgw.tgw_id
  tags               = merge(var.tags, {Name = "${var.resource_prefixes.aws_ec2_transit_gateway_route_table}-${local.tgw.basename}-${each.value}"})
}

# Transit peering associations
resource "aws_ec2_transit_gateway_route_table_association" "transit_peering" {
  for_each = local.transit_peering_map
  transit_gateway_attachment_id  = each.value.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this[local.tgw.transit_peering_association].id
}


# Blackholing
resource "aws_ec2_transit_gateway_route" "blackhole" {
  for_each                       = local.tgw.blackholes 
  blackhole                      = true
  destination_cidr_block         = each.value
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this[each.key].id
}

# Routing over transit peerings
resource "aws_ec2_transit_gateway_route" "transit" {
  for_each = {
    for e in flatten([
        for peering in keys(local.transit_peering_map): [
            for cidr in local.tgw.transit_routes[local.transit_peering_map[peering].dst]: {
                cidr = cidr
                attachment_id = local.transit_peering_map[peering].id
                peer = local.transit_peering_map[peering].dst
            }
        ]
    ]): "${e.cidr}-via-${e.attachment_id}" => {cidr = e.cidr, attachment_id = e.attachment_id}
  }
  destination_cidr_block         = each.value.cidr
  transit_gateway_attachment_id  = each.value.attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this[local.tgw.transit_peering_propagation].id
}
