locals {
  transit_attachments_list = [for k,v in var.transit_attachments[var.tgw]: {src = v.region, dst = v.peer_region , id=v.id} if v != {}]
  transit_accepters_list   = [for k,v in var.transit_accepters[var.tgw]: {src = v.region, dst = v.peer_region , id=v.id} if v != {}]
  transit_peering_list     = concat(local.transit_attachments_list,local.transit_accepters_list)
  transit_peering_map      = nonsensitive({ for e in local.transit_peering_list: "${e.src}-${e.dst}" => {src = e.src, dst=e.dst, id = e.id}})
  rfc1918                  = ["10.0.0.0/8","172.16.0.0/12","192.168.0.0/16"]
  tgw                      = var.transit_gateways[var.tgw]
}