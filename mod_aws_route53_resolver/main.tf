################################################################################
# Route53 outbound endpoints
################################################################################

resource "aws_security_group" "route53_outbound" {
  count                            = local.create ? 1 : 0
  name                             = "${var.resource_prefixes.aws_security_group}-${local.basename}-route53-outbound"
  description                      = "Allow Route53 outbound resolver"
  vpc_id                           = local.vpc_id
  tags                             = merge(local.tags,{Name = "${var.resource_prefixes.aws_security_group}-${local.basename}-route53-outbound"})
}

resource "aws_vpc_security_group_ingress_rule" "route53_outbound_ingress" {
  count                            = local.create ? 1 : 0
  from_port                        = 53
  to_port                          = 53
  ip_protocol                      = "UDP"
  cidr_ipv4                        = local.cidr
  security_group_id                = aws_security_group.route53_outbound[0].id
  description                      = "ingress: allow DNS from VPC CIDR ${local.cidr}"
  tags                             = merge(local.tags,{Name = "${var.resource_prefixes.aws_vpc_security_group_ingress_rule}-${local.basename}-dns-request-from-${local.cidr}"})
}

resource "aws_vpc_security_group_egress_rule" "route53_outbound_egress" {
  count                            = local.create ? length(local.az) : 0
  from_port                        = 53
  to_port                          = 53
  ip_protocol                      = "UDP"
  cidr_ipv4                        = "${local.forwarders[count.index]}/32"
  security_group_id                = aws_security_group.route53_outbound[0].id
  description                      = "egress: allow DNS forward to ${local.forwarders[count.index]}"
  tags                             = merge(local.tags,{Name = "${var.resource_prefixes.aws_vpc_security_group_egress_rule}-${local.basename}-dns-forward-to-${local.forwarders[count.index]}"})
}

resource "aws_route53_resolver_endpoint" "outbound" {
  count                            = local.create ? 1 : 0
  name                             = "${var.resource_prefixes.aws_route53_resolver_endpoint}-${local.basename}-route53-outbound"
  direction                        = "OUTBOUND"
  security_group_ids               = [ aws_security_group.route53_outbound[0].id ]
  tags                             = merge(local.tags,{Name = "${var.resource_prefixes.aws_route53_resolver_endpoint}-${local.basename}-route53-outbound"})
  dynamic "ip_address" {
    for_each = { for i,v in local.transit_subnet_ids: i => v }
    content {
      subnet_id = ip_address.value
    }
  }
}

################################################################################
# Route53 inbound endpoints
################################################################################

resource "aws_security_group" "route53_inbound" {
  count                            = local.create ? 1 : 0
  name                             = "${var.resource_prefixes.aws_security_group}-${local.basename}-route53-inbound"
  description                      = "Allow Route53 inbound resolver"
  vpc_id                           = local.vpc_id
  tags                             = merge(local.tags,{Name = "${var.resource_prefixes.aws_security_group}-${local.basename}-route53-inbound"})
}

resource "aws_vpc_security_group_ingress_rule" "route53_inbound_ingress" {
  count                            = local.create ? 1 : 0
  from_port                        = 53
  to_port                          = 53
  ip_protocol                      = "UDP"
  cidr_ipv4                        = "0.0.0.0/0"
  security_group_id                = aws_security_group.route53_inbound[0].id
  description                      = "ingress: allow DNS from 0.0.0.0/0"
  tags                             = merge(local.tags,{Name = "${var.resource_prefixes.aws_vpc_security_group_ingress_rule}-${local.basename}-dns-request-from-0.0.0.0/0"})
} 

resource "aws_vpc_security_group_egress_rule" "route53_inbound_egress" {
  count                            = local.create ? 1 : 0
  from_port                        = 53
  to_port                          = 53
  ip_protocol                      = "UDP"
  cidr_ipv4                        = "0.0.0.0/0"
  security_group_id                = aws_security_group.route53_inbound[0].id
  description                      = "egress: allow DNS to 0.0.0.0/0"
  tags                             = merge(local.tags,{Name = "${var.resource_prefixes.aws_vpc_security_group_egress_rule}-${local.basename}-dns-forward-to-0.0.0.0/0"})
}

resource "aws_route53_resolver_endpoint" "inbound" {
  count                            = local.create ? 1 : 0
  name                             = "${var.resource_prefixes.aws_route53_resolver_endpoint}-${local.basename}-route53-inbound"
  direction                        = "INBOUND"
  security_group_ids               = [ aws_security_group.route53_inbound[0].id ]
  tags                             = merge(local.tags,{Name = "${var.resource_prefixes.aws_route53_resolver_endpoint}-${local.basename}-route53-inbound"})
  dynamic "ip_address" {
    for_each = { for i,v in local.transit_subnet_ids: i => v }
    content {
      subnet_id = ip_address.value
    }
  }
}

################################################################################
# Route53 forward resolver rules for on-prem zones
################################################################################

resource "aws_route53_resolver_rule" "forward" {
  for_each                         = local.create ? { for i,v in local.forwarded_zones: v => v } : {}
  domain_name                      = each.value
  name                             = "${var.resource_prefixes.aws_route53_resolver_rule_forward}-${replace(each.value,".","_")}"
  rule_type                        = "FORWARD"
  resolver_endpoint_id             = aws_route53_resolver_endpoint.outbound[0].id
  tags                             = merge(local.tags,{Name = "${var.resource_prefixes.aws_route53_resolver_rule_forward}-${replace(each.value,".","_")}"})
  dynamic "target_ip" {
    for_each = local.forwarders
    content {
      ip = target_ip.value
    }
  }
}

resource "aws_route53_resolver_rule_association" "forward" {
  for_each                         = local.create ? aws_route53_resolver_rule.forward : {}
  resolver_rule_id                 = each.value.id
  vpc_id                           = local.vpc_id
}

################################################################################
# Route53 system resolver rules
################################################################################

resource "aws_route53_resolver_rule" "system" {
  for_each                         = local.create ? { for i,v in local.system_zones: v => v } : {}
  domain_name                      = each.value
  name                             = "${var.resource_prefixes.aws_route53_resolver_rule_system}-${replace(each.value,".","_")}"
  rule_type                        = "SYSTEM"
  tags                             = merge(local.tags,{Name = "${var.resource_prefixes.aws_route53_resolver_rule_system}-${replace(each.value,".","_")}"})
}

resource "aws_route53_resolver_rule_association" "system" {
  for_each                         = local.create ? aws_route53_resolver_rule.system : {}
  resolver_rule_id                 = each.value.id
  vpc_id                           = local.vpc_id
}


################################################################################
# RAM Sharing
# # See also "jinja-ram-associations.tf"
################################################################################

# Create resource share
resource "aws_ram_resource_share" "this" {
  count = local.create ? 1 : 0
  name = "${var.resource_prefixes.aws_ram_resource_share}-rslvr-rr-${local.basename}"
  allow_external_principals = true
  tags = merge(local.tags, {Name = "${var.resource_prefixes.aws_ram_resource_share}-rslvr-rr-${local.basename}"})
}

# Share rules
resource "aws_ram_resource_association" "system_rules" {
  for_each           = local.create ? aws_route53_resolver_rule.system : {}
  resource_arn       = each.value.arn
  resource_share_arn = aws_ram_resource_share.this[0].arn
}

resource "aws_ram_resource_association" "forward_rules" {
  for_each           = local.create ? aws_route53_resolver_rule.forward : {}
  resource_arn       = each.value.arn
  resource_share_arn = aws_ram_resource_share.this[0].arn
}
