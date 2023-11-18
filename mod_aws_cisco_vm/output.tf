output output {
    value = {
        sg_public_id           = local.create ? aws_security_group.public[0].id : null
        sg_private_id          = local.create ? aws_security_group.private[0].id : null
        eni_public_ids         = local.create ? aws_network_interface.public[*].id : null
        eni_public_ips         = local.create ? aws_network_interface.public[*].private_ip : null
        eni_private_ids        = local.create ? aws_network_interface.private[*].id : null
        eni_private_ips        = local.create ? aws_network_interface.private[*].private_ip : null
        eip_ids                = local.create ? aws_eip.this[*].id : null
        eip_ips                = local.create ? aws_eip.this[*].public_ip : null
        instance_ids           = local.create ? aws_instance.this[*].id : null
        # TGW Connect Peering
        bgp_peer_arn       = local.vpc.create ? aws_ec2_transit_gateway_connect_peer.this[*].arn : null
        bgp_peer_asn       = local.vpc.create ? aws_ec2_transit_gateway_connect_peer.this[*].bgp_asn : null
        bgp_peer_address   = local.vpc.create ? aws_ec2_transit_gateway_connect_peer.this[*].bgp_peer_address : null
        bgp_tgw_address    = local.vpc.create ? aws_ec2_transit_gateway_connect_peer.this[*].bgp_transit_gateway_addresses : null
        inside_cidr_blocks = local.vpc.create ? aws_ec2_transit_gateway_connect_peer.this[*].inside_cidr_blocks : null
        tgw_address         = local.vpc.create ? aws_ec2_transit_gateway_connect_peer.this[*].transit_gateway_address : null
    }
}