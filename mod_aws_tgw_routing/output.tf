output output {
  value = {
    transit_peering_map = local.transit_peering_map
    transit_route_tables = { for k,v in aws_ec2_transit_gateway_route_table.this: k => v.id }
    }
  }
