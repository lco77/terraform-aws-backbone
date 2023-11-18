output output {
  value = {
    # Inbound VPCEs
    vpce_inbound_id = local.create ? aws_route53_resolver_endpoint.inbound[0].id : null
    vpce_inbound_ips = local.create ? [ for i,v in aws_route53_resolver_endpoint.inbound[0].ip_address: v.ip] : null
    vpce_inbound_subnet_ids = local.create ? [ for i,v in aws_route53_resolver_endpoint.inbound[0].ip_address: v.subnet_id] : null
    # Outbound VPCEs
    vpce_outbound_id = local.create ? local.create ? aws_route53_resolver_endpoint.outbound[0].id : null : null
    vpce_outbound_ips = local.create ? [ for i,v in aws_route53_resolver_endpoint.outbound[0].ip_address: v.ip] : null
    vpce_outbound_subnet_ids = local.create ? [ for i,v in aws_route53_resolver_endpoint.outbound[0].ip_address: v.subnet_id] : null
    # Shared Rules
    forward_rules_ids = local.create ? [for i,v in aws_route53_resolver_rule.forward: v.id] : null
    system_rules_ids = local.create ? [for i,v in aws_route53_resolver_rule.system: v.id] : null
    resolver_rules_ram_id = local.create ? aws_ram_resource_share.this[0].arn : null
  }
}

