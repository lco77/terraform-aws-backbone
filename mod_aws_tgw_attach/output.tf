output output {
  value = {
    for k,v in aws_ec2_transit_gateway_peering_attachment.this: k => {
        id          = v.id
        tgw_id      = v.transit_gateway_id
        region      = var.tgw
        peer_region = lookup(var.map_region_to_code,v.peer_region,"")
        peer_tgw_id = v.peer_transit_gateway_id
    }
  }
}