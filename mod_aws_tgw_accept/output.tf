output output {
  value = {
    for k,v in aws_ec2_transit_gateway_peering_attachment_accepter.this: k => {
        id            = v.id
        tgw_id        = v.transit_gateway_id
        peer_region   = lookup(v.tags,"SourceRegion","")
        region        = var.tgw
        peer_tgw_id   = v.peer_transit_gateway_id
    }
  }
}