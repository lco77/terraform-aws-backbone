
################################################################################
# DHCP Options set
################################################################################
resource "aws_vpc_dhcp_options" "this" {
  count                            = var.vpc.create ? 1 : 0
  provider                         = aws.vpc
  domain_name                      = local.custom_dns ? var.vpc.custom_dns.domain : local.route53_domain.name
  domain_name_servers              = ["AmazonProvidedDNS"]
  tags                             = merge(local.tags,{Name = "${var.resource_prefixes.aws_vpc_dhcp_options}-${local.basename}"})
}

################################################################################
# VPC
################################################################################
resource "aws_vpc" "this" {
  count                            = var.vpc.create ? 1 : 0
  provider                         = aws.vpc
  cidr_block                       = var.vpc.cidr
  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = var.vpc.dual_stack
  tags                             = merge(local.tags,{Name = "${var.resource_prefixes.aws_vpc}-${local.basename}"})
}

resource "aws_vpc_ipv4_cidr_block_association" "this" {
  for_each                          = var.vpc.create ? try({for i,v in var.vpc.cidr_secondary: v => v},{}) : {}
  vpc_id                            = aws_vpc.this[0].id
  cidr_block                        = each.value
}

resource "aws_vpc_dhcp_options_association" "this" {
  count                            = var.vpc.create ? 1 : 0
  provider                         = aws.vpc
  vpc_id                           = aws_vpc.this[0].id
  dhcp_options_id                  = aws_vpc_dhcp_options.this[0].id
}

################################################################################
# Internet Gateway
################################################################################
resource "aws_internet_gateway" "this" {
  count                            = local.create_public_subnets && var.vpc.public.dia ? 1 : 0
  provider                         = aws.vpc
  vpc_id                           = aws_vpc.this[0].id
  tags                             = merge(local.tags,{Name = "${var.resource_prefixes.aws_internet_gateway}-${local.basename}"})
}

resource "aws_egress_only_internet_gateway" "this" {
  count                            = local.create_public_subnets && var.vpc.public.dia && var.vpc.dual_stack ? 1 : 0
  provider                         = aws.vpc
  vpc_id                           = aws_vpc.this[0].id
  tags                             = merge(local.tags,{Name = "${var.resource_prefixes.aws_egress_only_internet_gateway}-${local.basename}"})
}

################################################################################
# NAT Gateway
################################################################################

resource "aws_eip" "nat" {
  for_each = local.create_public_subnets && local.create_private_subnets && var.vpc.public.dia && var.vpc.private.dia ? {for i,v in distinct(var.vpc.public.az): v => i} : {}
  provider                         = aws.vpc
  domain                           = "vpc"
  tags                             = merge(local.tags,{Name = "${var.resource_prefixes.aws_eip}-${local.basename}-nat-${var.vpc.public.az[each.value]}"})
  depends_on                       = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  for_each = local.create_public_subnets && local.create_private_subnets && var.vpc.public.dia && var.vpc.private.dia ? {for i,v in distinct(var.vpc.public.az): v => i} : {}
  provider                         = aws.vpc
  subnet_id                        = element([for k,v in aws_subnet.public: v.id], each.value)
  allocation_id                    = aws_eip.nat[each.key].id
  tags                             = merge(local.tags,{Name = "${var.resource_prefixes.aws_nat_gateway}-${local.basename}-${var.vpc.public.az[each.value]}"})
  depends_on                       = [aws_internet_gateway.this]
}


################################################################################
# Publiс Subnets
################################################################################

resource "aws_subnet" "public" {
  for_each                         = local.public_subnets
  provider                         = aws.vpc
  assign_ipv6_address_on_creation  = var.vpc.dual_stack
  availability_zone                = each.value.availability_zone
  cidr_block                       = each.value.cidr_block
  ipv6_cidr_block                  = var.vpc.dual_stack ? cidrsubnet(aws_vpc.this[0].ipv6_cidr_block, 8, each.value.index) : null
  vpc_id                           = aws_vpc.this[0].id
  tags                             = merge(local.tags,{Name = each.value.name})
}

resource "aws_route_table" "public" {
  count                            = local.create_public_subnets ? 1 : 0
  provider                         = aws.vpc
  vpc_id                           = aws_vpc.this[0].id
  tags                             = merge(local.tags,{Name = "${var.resource_prefixes.aws_route_table}-${local.basename}-public"})
}

resource "aws_route_table_association" "public" {
  for_each                         = local.public_subnets
  provider                         = aws.vpc
  subnet_id                        = aws_subnet.public[each.value.cidr_block].id
  route_table_id                   = aws_route_table.public[0].id
}

resource "aws_route" "public_internet_gateway" {
  count                            = local.create_public_subnets && var.vpc.public.dia ? 1 : 0
  provider                         = aws.vpc
  route_table_id                   = aws_route_table.public[0].id
  destination_cidr_block           = "0.0.0.0/0"
  gateway_id                       = aws_internet_gateway.this[0].id
}

resource "aws_route" "public_internet_gateway_ipv6" {
  count                            = local.create_public_subnets && var.vpc.public.dia && var.vpc.dual_stack ? 1 : 0
  provider                         = aws.vpc
  route_table_id                   = aws_route_table.public[0].id
  destination_ipv6_cidr_block      = "::/0"
  gateway_id                       = aws_internet_gateway.this[0].id
}

################################################################################
# Private Subnets
################################################################################

resource "aws_subnet" "private" {
  for_each                         = local.private_subnets
  provider                         = aws.vpc
  availability_zone                = each.value.availability_zone
  cidr_block                       = each.value.cidr_block
  vpc_id                           = aws_vpc.this[0].id
  tags                             = merge(local.tags,{Name = each.value.name})
}

resource "aws_route_table" "private" {
  count                            = local.create_private_subnets && !var.vpc.private.dia ? 1 : 0
  provider                         = aws.vpc
  vpc_id                           = aws_vpc.this[0].id
  tags                             = merge(local.tags,{Name = "${var.resource_prefixes.aws_route_table}-${local.basename}-private"})
}

resource "aws_route_table" "private_with_nat" {
  for_each                         = local.create_private_subnets && var.vpc.private.dia ? {for i,v in distinct(var.vpc.private.az): v => i} : {}
  provider                         = aws.vpc
  vpc_id                           = aws_vpc.this[0].id
  tags                             = merge(local.tags,{Name = "${var.resource_prefixes.aws_route_table}-${local.basename}-private-${each.key}"})
}

resource "aws_route_table_association" "private" {
  for_each                         = local.create_private_subnets && !var.vpc.private.dia ? local.private_subnets : {}
  provider                         = aws.vpc
  subnet_id                        = aws_subnet.private[each.value.cidr_block].id
  route_table_id                   = aws_route_table.private[0].id
}

resource "aws_route_table_association" "private_with_nat" {
  for_each                         = local.create_private_subnets && var.vpc.private.dia ? local.private_subnets : {}
  provider                         = aws.vpc
  subnet_id                        = aws_subnet.private[each.value.cidr_block].id
  route_table_id                   = aws_route_table.private_with_nat[each.value.az].id
}

resource "aws_route" "nat_gateway" {
  for_each                         = local.create_private_subnets && var.vpc.private.dia ? {for i,v in distinct(var.vpc.private.az): v => i} : {}
  provider                         = aws.vpc
  route_table_id                   = aws_route_table.private_with_nat[each.key].id
  destination_cidr_block           = "0.0.0.0/0"
  nat_gateway_id                   = aws_nat_gateway.this[each.key].id
}

################################################################################
# Gateway endpoints
################################################################################

# S3 Gateway endpoint
resource "aws_vpc_endpoint" "s3" {
  count = (local.create_private_subnets || local.create_public_subnets) && (var.vpc.private.vpce_s3 || var.vpc.public.vpce_s3) ? 1 : 0
  provider                         = aws.vpc
  vpc_id                           = aws_vpc.this[0].id
  service_name                     = "com.amazonaws.${var.map_code_to_region[var.vpc.region]}.s3"
  route_table_ids                  = compact(concat(
    local.create_private_subnets && var.vpc.private.dia && var.vpc.private.vpce_s3  ? [for k,v in aws_route_table.private_with_nat: v.id] : [],
    local.create_private_subnets && !var.vpc.private.dia && var.vpc.private.vpce_s3 ? [aws_route_table.private[0].id] : [],
    local.create_public_subnets && var.vpc.public.vpce_s3 ? [aws_route_table.public[0].id] : []
  ))
  tags                             = merge(local.tags,{Name = "vpce-s3-${local.basename}"})
}

# DynamoDB Gateway endpoint
resource "aws_vpc_endpoint" "dynamodb" {
  count = (local.create_private_subnets || local.create_public_subnets) && (var.vpc.private.vpce_dynamodb || var.vpc.public.vpce_dynamodb) ? 1 : 0
  provider                         = aws.vpc
  vpc_id                           = aws_vpc.this[0].id
  service_name                     = "com.amazonaws.${var.map_code_to_region[var.vpc.region]}.dynamodb"
  route_table_ids                  = compact(concat(
    local.create_private_subnets && var.vpc.private.dia && var.vpc.private.vpce_dynamodb  ? [for k,v in aws_route_table.private_with_nat: v.id] : [],
    local.create_private_subnets && !var.vpc.private.dia && var.vpc.private.vpce_dynamodb ? [aws_route_table.private[0].id] : [],
    local.create_public_subnets && var.vpc.public.vpce_dynamodb ? [aws_route_table.public[0].id] : []
  ))
  tags                             = merge(local.tags,{Name = "vpce-dynamodb-${local.basename}"})
}

################################################################################
# Transit Gateway Subnets
################################################################################

resource "aws_subnet" "transit" {
  for_each                         = local.transit_subnets
  provider                         = aws.vpc
  availability_zone                = each.value.availability_zone
  cidr_block                       = each.value.cidr_block
  vpc_id                           = aws_vpc.this[0].id
  tags                             = merge(local.tags,{Name = each.value.name})
}

resource "aws_route_table" "transit" {
  count                            = local.create_transit_subnets ? 1 : 0
  provider                         = aws.vpc
  vpc_id                           = aws_vpc.this[0].id
  tags                             = merge(local.tags,{Name = "${var.resource_prefixes.aws_route_table}-${local.basename}-transit"})
}

resource "aws_route_table_association" "transit" {
  for_each                         = local.create_transit_subnets ? local.transit_subnets : {}
  provider                         = aws.vpc
  subnet_id                        = aws_subnet.transit[each.value.cidr_block].id
  route_table_id                   = aws_route_table.transit[0].id
}

################################################################################
# Transit Attachment
################################################################################
resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  count                            = var.vpc.create && var.vpc.transit != {} ? 1 : 0
  provider                         = aws.vpc
  subnet_ids                       = [for k,v in aws_subnet.transit: v.id]
  transit_gateway_id               = lookup({for k,v in var.tgw: v.region => v.tgw_id},var.vpc.region,"")
  vpc_id                           = aws_vpc.this[0].id
  appliance_mode_support           = "enable"
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  tags                             = merge(local.tags,{Name = "${var.resource_prefixes.aws_ec2_transit_gateway_vpc_attachment}-${local.basename}"})
}

# Trigger acceptance for cross-account attachment
resource "aws_ec2_transit_gateway_vpc_attachment_accepter" "this" {
  count                            = var.vpc.create && var.vpc.transit != {} && lookup({for k,v in var.tgw: v.region => v.account},var.vpc.region,"") != var.vpc.account ? 1 : 0
  provider                         = aws.tgw
  transit_gateway_attachment_id    = aws_ec2_transit_gateway_vpc_attachment.this[0].id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  tags                             = merge(local.tags,{Name = "${var.resource_prefixes.aws_ec2_transit_gateway_vpc_attachment_accepter}-${local.basename}"})
}

# Create association within same account without waiting for accepter
resource "aws_ec2_transit_gateway_route_table_association" "this" {
  count                            = var.vpc.create && var.vpc.transit != {} && lookup({for k,v in var.tgw: v.region => v.account},var.vpc.region,"") == var.vpc.account ? 1 : 0
  provider                         = aws.tgw
  transit_gateway_attachment_id    = aws_ec2_transit_gateway_vpc_attachment.this[0].id
  transit_gateway_route_table_id   = var.rtb[var.vpc.region].transit_route_tables[var.vpc.transit.associate]
}

# Create association with another account after accepter
resource "aws_ec2_transit_gateway_route_table_association" "this_remote_account" {
  count                            = var.vpc.create && var.vpc.transit != {} && lookup({for k,v in var.tgw: v.region => v.account},var.vpc.region,"") != var.vpc.account ? 1 : 0
  provider                         = aws.tgw
  transit_gateway_attachment_id    = aws_ec2_transit_gateway_vpc_attachment.this[0].id
  transit_gateway_route_table_id   = var.rtb[var.vpc.region].transit_route_tables[var.vpc.transit.associate]
  depends_on                       = [  aws_ec2_transit_gateway_vpc_attachment_accepter.this ]
}

# Create propagations within same account without waiting for accepter
resource "aws_ec2_transit_gateway_route_table_propagation" "this" {
  count                            = var.vpc.create && var.vpc.transit != {} && lookup({for k,v in var.tgw: v.region => v.account},var.vpc.region,"") == var.vpc.account ? length(var.vpc.transit.propagate) : 0
  provider                         = aws.tgw
  transit_gateway_attachment_id    = aws_ec2_transit_gateway_vpc_attachment.this[0].id
  transit_gateway_route_table_id   = var.rtb[var.vpc.region].transit_route_tables[var.vpc.transit.propagate[count.index]]
}

# Create propagations with another account after accepter
resource "aws_ec2_transit_gateway_route_table_propagation" "this_remote_account" {
  count                            = var.vpc.create && var.vpc.transit != {} && lookup({for k,v in var.tgw: v.region => v.account},var.vpc.region,"") != var.vpc.account ? length(var.vpc.transit.propagate) : 0
  provider                         = aws.tgw
  transit_gateway_attachment_id    = aws_ec2_transit_gateway_vpc_attachment.this[0].id
  transit_gateway_route_table_id   = var.rtb[var.vpc.region].transit_route_tables[var.vpc.transit.propagate[count.index]]
  depends_on                       = [  aws_ec2_transit_gateway_vpc_attachment_accepter.this ]
}

################################################################################
# Transit Routing
################################################################################
resource "aws_route" "transit_default" {
  count                            = local.create_transit_subnets && var.vpc.transit != {} ? 1 : 0
  provider                         = aws.vpc
  route_table_id                   = aws_route_table.transit[0].id
  destination_cidr_block           = "0.0.0.0/0"
  transit_gateway_id               = lookup({for k,v in var.tgw: v.region => v.tgw_id},var.vpc.region,"")
  depends_on                       = [ aws_ec2_transit_gateway_vpc_attachment.this ]
}

resource "aws_route" "private_default" {
  count                            = local.create_private_subnets && !var.vpc.private.dia && var.vpc.transit != {} ? 1 : 0
  provider                         = aws.vpc
  route_table_id                   = aws_route_table.private[0].id
  destination_cidr_block           = "0.0.0.0/0"
  transit_gateway_id               = lookup({for k,v in var.tgw: v.region => v.tgw_id},var.vpc.region,"")
  depends_on                       = [ aws_ec2_transit_gateway_vpc_attachment.this ]
}

resource "aws_route" "private_rfc1918" {
  for_each = local.create_private_subnets && var.vpc.private.dia && var.vpc.transit != {} ? {
    for e in flatten([
      for cidr in local.rfc1918: [
        for i,v in distinct(var.vpc.private.az): {
          cidr  = cidr
          index = i
          az    = v
        }
      ]
    ]): "${e.cidr}_${e.az}" => {cidr = e.cidr, rtb = aws_route_table.private_with_nat[e.az].id}
  } : {}
  provider                         = aws.vpc
  route_table_id                   = each.value.rtb
  destination_cidr_block           = each.value.cidr
  transit_gateway_id               = lookup({for k,v in var.tgw: v.region => v.tgw_id},var.vpc.region,"")
  depends_on                       = [ aws_ec2_transit_gateway_vpc_attachment.this ]
}

resource "aws_route" "public_rfc1918" {
  for_each = local.create_public_subnets && var.vpc.public.rfc1918_routes && var.vpc.transit != {} ? { for i,v in local.rfc1918: i=>v}  : {}
  provider                         = aws.vpc
  route_table_id                   = aws_route_table.public[0].id
  destination_cidr_block           = each.value
  transit_gateway_id               = lookup({for k,v in var.tgw: v.region => v.tgw_id},var.vpc.region,"")
  depends_on                       = [ aws_ec2_transit_gateway_vpc_attachment.this ]
}

################################################################################
# Custom DNS: Route53 outbound resolver endpoint
################################################################################

resource "aws_security_group" "route53_outbound" {
  count                            = local.custom_dns ? 1 : 0
  provider                         = aws.vpc
  name                             = "${var.resource_prefixes.aws_security_group}-${local.basename}-route53-outbound"
  description                      = "Allow Route53 outbound resolver"
  vpc_id                           = aws_vpc.this[0].id
  tags                             = merge(local.tags,{Name = "${var.resource_prefixes.aws_security_group}-${local.basename}-route53-outbound"})
}

resource "aws_vpc_security_group_ingress_rule" "route53_outbound_ingress" {
  count                            = local.custom_dns ? 1 : 0
  provider                         = aws.vpc
  from_port                        = 53
  to_port                          = 53
  ip_protocol                      = "UDP"
  cidr_ipv4                        = var.vpc.cidr
  security_group_id                = aws_security_group.route53_outbound[0].id
  description                      = "ingress: allow DNS from VPC CIDR ${var.vpc.cidr}"
  tags                             = merge(local.tags,{Name = "${var.resource_prefixes.aws_vpc_security_group_ingress_rule}-${local.basename}-dns-request-from-${var.vpc.cidr}"})
} 

resource "aws_vpc_security_group_egress_rule" "route53_outbound_egress" {
  count                            = local.custom_dns ? 1 : 0
  provider                         = aws.vpc
  from_port                        = 53
  to_port                          = 53
  ip_protocol                      = "UDP"
  cidr_ipv4                        = "0.0.0.0/0"
  security_group_id                = aws_security_group.route53_outbound[0].id
  description                      = "egress: allow DNS to any"
  tags                             = merge(local.tags,{Name = "${var.resource_prefixes.aws_vpc_security_group_egress_rule}-${local.basename}-dns-forward-to-any"})
}

resource "aws_route53_resolver_endpoint" "outbound" {
  count                            = local.custom_dns ? 1 : 0
  provider                         = aws.vpc
  name                             = "${var.resource_prefixes.aws_route53_resolver_endpoint}-${local.basename}-route53-outbound"
  direction                        = "OUTBOUND"
  security_group_ids               = [ aws_security_group.route53_outbound[0].id ]
  tags                             = merge(local.tags,{Name = "${var.resource_prefixes.aws_route53_resolver_endpoint}-${local.basename}-route53-outbound"})
  dynamic "ip_address" {
    for_each = aws_subnet.transit
    content {
      subnet_id = ip_address.value.id
    }
  }
}

################################################################################
# Custom DNS: Route53 resolver rules
################################################################################

resource "aws_route53_resolver_rule" "custom_forward" {
  for_each                         = local.custom_dns ? local.custom_forward : {}
  provider                         = aws.vpc
  domain_name                      = each.value.zone
  name                             = each.value.name
  rule_type                        = "FORWARD"
  resolver_endpoint_id             = aws_route53_resolver_endpoint.outbound[0].id
  tags                             = merge(local.tags,{Name = each.value.name})
  dynamic "target_ip" {
    for_each = local.forwarders
    content {
      ip = target_ip.value
    } 
  }
}

resource "aws_route53_resolver_rule_association" "custom_forward" {
  for_each                         = local.custom_dns ? aws_route53_resolver_rule.custom_forward : {}
  provider                         = aws.vpc
  resolver_rule_id                 = each.value.id
  vpc_id                           = aws_vpc.this[0].id
}

################################################################################
# Route53 local VPC domain (in VPC account)
# - create local zone into VPC account
################################################################################

# resource "aws_route53_zone" "local_domain" {
#   count      = local.create_transit_subnets ? 1 : 0
#   provider   = aws.vpc
#   name       = "${local.basename}.${local.route53_domain.name}"
#   vpc {
#     vpc_id     = aws_vpc.this[0].id
#     vpc_region = var.map_code_to_region[var.region]
#   }
#   # Prevent the deletion of associated VPCs after the initial creation.
#   lifecycle {
#     ignore_changes = [vpc]
#   }
# }

################################################################################
# Route53 local VPC domain (in VPC account) association - same account
# - associate local zone will ALL core VPCs
################################################################################

# resource "aws_route53_zone_association" "local_domain" {
#   for_each      = local.create_transit_subnets && lookup({for k,v in local.core_vpcs: k => v.account},var.region,"") == var.account ? {for k,v in local.core_vpcs: "core_${k}" => {vpc_id = v.vpc_id, region = k}} : {}
#   provider   = aws.vpc
#   vpc_id     = each.value.vpc_id
#   vpc_region = var.map_code_to_region[each.value.region]
#   zone_id    = aws_route53_zone.local_domain[0].id
# }

################################################################################
# Route53 local VPC domain (in VPC account) association - cross account
# - associate local zone will ALL core VPCs
################################################################################

# resource "aws_route53_vpc_association_authorization" "local_domain_cross_account" {
#   for_each      = local.create_transit_subnets && lookup({for k,v in local.core_vpcs: k => v.account},var.region,"") != var.account ? {for k,v in local.core_vpcs: "core_${k}" => {vpc_id = v.vpc_id, region = k}} : {}
#   provider   = aws.vpc
#   vpc_id     = each.value.vpc_id
#   vpc_region = var.map_code_to_region[each.value.region]
#   zone_id    = aws_route53_zone.local_domain[0].id
# }

# resource "aws_route53_zone_association" "local_domain_cross_account" {
#   for_each      = local.create_transit_subnets && lookup({for k,v in local.core_vpcs: k => v.account},var.region,"") != var.account ? {for k,v in local.core_vpcs: "core_${k}" => {vpc_id = v.vpc_id, region = k}} : {}
#   provider   = aws.r53
#   vpc_id     = each.value.vpc_id
#   vpc_region = var.map_code_to_region[each.value.region]
#   zone_id    = aws_route53_zone.local_domain[0].id
#   depends_on = [ aws_route53_vpc_association_authorization.local_domain_cross_account ]
# }

################################################################################
# Route53 local VPC domain (in route53 account)
################################################################################

# resource "aws_route53_zone" "local_domain" {
#   count      = local.create_transit_subnets ? 1 : 0
#   provider   = aws.r53
#   name       = "${local.basename}.${local.route53_domain.name}"
#   dynamic "vpc" {
#     for_each = local.core_vpcs
#     content {
#       vpc_id     = vpc.value.vpc_id
#       vpc_region = var.map_code_to_region[vpc.value.region]
#     }
#   }
#   # Prevent the deletion of associated VPCs after the initial creation.
#   lifecycle {
#     ignore_changes = [vpc]
#   }
# }

################################################################################
# Route53 local VPC domain (in route53 account) association - same account
################################################################################

# resource "aws_route53_zone_association" "local_domain" {
#   count      = local.create_transit_subnets && lookup({for k,v in var.tgw: v.region => v.account},var.region,"") == var.account ? 1 : 0
#   provider   = aws.vpc
#   vpc_id     = aws_vpc.this[0].id
#   vpc_region = var.map_code_to_region[var.region]
#   zone_id    = aws_route53_zone.local_domain[0].id
# }

################################################################################
# Route53 local VPC domain (in route53 account) association - cross account
################################################################################

# resource "aws_route53_vpc_association_authorization" "local_domain_cross_account" {
#   count      = local.create_transit_subnets && lookup({for k,v in var.tgw: v.region => v.account},var.region,"") != var.account ? 1 : 0
#   provider   = aws.r53
#   vpc_id     = aws_vpc.this[0].id
#   vpc_region = var.map_code_to_region[var.region]
#   zone_id    = aws_route53_zone.local_domain[0].id
# }

# resource "aws_route53_zone_association" "local_domain_cross_account" {
#   count      = local.create_transit_subnets && lookup({for k,v in var.tgw: v.region => v.account},var.region,"") != var.account ? 1 : 0
#   provider   = aws.vpc
#   vpc_id     = aws_vpc.this[0].id
#   vpc_region = var.map_code_to_region[var.region]
#   zone_id    = aws_route53_zone.local_domain[0].id
#   depends_on = [ aws_route53_vpc_association_authorization.domain_cross_account ]
# }

################################################################################
# Shared DNS: Route53 landing zone domain association - same account
################################################################################

resource "aws_route53_zone_association" "domain" {
  count      = !local.custom_dns && local.create_transit_subnets && lookup({for k,v in var.tgw: v.region => v.account},var.vpc.region,"") == var.vpc.account ? 1 : 0
  provider   = aws.vpc
  vpc_id     = aws_vpc.this[0].id
  vpc_region = var.map_code_to_region[var.vpc.region]
  zone_id    = local.route53_domain.id
}

################################################################################
# Shared DNS: Route53 landing zone domain association - cross account
################################################################################

resource "aws_route53_vpc_association_authorization" "domain_cross_account" {
  count      = !local.custom_dns && local.create_transit_subnets && lookup({for k,v in var.tgw: v.region => v.account},var.vpc.region,"") != var.vpc.account ? 1 : 0
  provider   = aws.r53
  vpc_id     = aws_vpc.this[0].id
  vpc_region = var.map_code_to_region[var.vpc.region]
  zone_id    = local.route53_domain.id
}

resource "aws_route53_zone_association" "domain_cross_account" {
  count      = !local.custom_dns && local.create_transit_subnets && lookup({for k,v in var.tgw: v.region => v.account},var.vpc.region,"") != var.vpc.account ? 1 : 0
  provider   = aws.vpc
  vpc_id     = aws_vpc.this[0].id
  vpc_region = var.map_code_to_region[var.vpc.region]
  zone_id    = local.route53_domain.id
  depends_on = [ aws_route53_vpc_association_authorization.domain_cross_account ]
}

################################################################################
# Shared DNS: Route53 hosted zones associations - same account
################################################################################

resource "aws_route53_zone_association" "hosted_zones" {
  for_each = !local.custom_dns && local.create_transit_subnets && lookup({for k,v in var.tgw: v.region => v.account},var.vpc.region,"") == var.vpc.account ? local.route53_zones : {}
  provider = aws.vpc
  vpc_id  = aws_vpc.this[0].id
  zone_id = each.value.id
}

################################################################################
# Shared DNS: Route53 hosted zones associations - cross account
################################################################################

resource "aws_route53_vpc_association_authorization" "hosted_zones_cross_account" {
  for_each   = !local.custom_dns && local.create_transit_subnets && lookup({for k,v in var.tgw: v.region => v.account},var.vpc.region,"") != var.vpc.account ? local.route53_zones : {}
  provider   = aws.r53
  vpc_id     = aws_vpc.this[0].id
  vpc_region = var.map_code_to_region[var.vpc.region]
  zone_id    = each.value.id
}

resource "aws_route53_zone_association" "hosted_zones_cross_account" {
  for_each   = !local.custom_dns && local.create_transit_subnets && lookup({for k,v in var.tgw: v.region => v.account},var.vpc.region,"") != var.vpc.account ? local.route53_zones : {}
  provider   = aws.vpc
  vpc_id     = aws_vpc.this[0].id
  vpc_region = var.map_code_to_region[var.vpc.region]
  zone_id    = each.value.id
  depends_on = [ aws_route53_vpc_association_authorization.hosted_zones_cross_account ]
}

################################################################################
# Shared DNS: Route53 forward rules
################################################################################

resource "aws_route53_resolver_rule_association" "forward" {
  for_each                         = !local.custom_dns && local.create_transit_subnets ? {for i,v in nonsensitive(local.route53_resolver.forward_rules_ids): v=>v} : {}
  provider                         = aws.vpc
  resolver_rule_id                 = each.value
  vpc_id                           = aws_vpc.this[0].id
}

################################################################################
# Shared DNS: Route53 system rules
################################################################################

resource "aws_route53_resolver_rule_association" "system" {
  for_each                         = !local.custom_dns && local.create_transit_subnets ? {for i,v in nonsensitive(local.route53_resolver.system_rules_ids): v=>v} : {}
  provider                         = aws.vpc
  resolver_rule_id                 = each.value
  vpc_id                           = aws_vpc.this[0].id
}

################################################################################
# Optional Debug VMs
################################################################################

resource "aws_security_group" "vm_debug" {
  count                            = (local.create_public_subnets || local.create_private_subnets || local.create_transit_subnets) && (var.vpc.public.vm_debug ||  var.vpc.private.vm_debug || var.vpc.transit.vm_debug) ? 1 : 0
  provider                         = aws.vpc
  name                             = "${var.resource_prefixes.aws_security_group}-${local.basename}-vmdebug"
  description                      = "Do not delete !"
  vpc_id                           = aws_vpc.this[0].id
  tags                             = merge(local.tags,{Name = "${var.resource_prefixes.aws_security_group}-${local.basename}-vmdebug"})
}

resource "aws_vpc_security_group_egress_rule" "vm_debug" {
  count                            = (local.create_public_subnets || local.create_private_subnets || local.create_transit_subnets) && (var.vpc.public.vm_debug ||  var.vpc.private.vm_debug || var.vpc.transit.vm_debug) ? 1 : 0
  provider                         = aws.vpc
  security_group_id                = aws_security_group.vm_debug[0].id
  cidr_ipv4                        = "0.0.0.0/0"
  ip_protocol                      = "-1"
  tags                             = merge(local.tags,{Name = "${var.resource_prefixes.aws_vpc_security_group_egress_rule}-${local.basename}-vmdebug-egress"})
}

resource "aws_vpc_security_group_ingress_rule" "vm_debug" {
  count                            = (local.create_public_subnets || local.create_private_subnets || local.create_transit_subnets) && (var.vpc.public.vm_debug ||  var.vpc.private.vm_debug || var.vpc.transit.vm_debug) ? 1 : 0
  provider                         = aws.vpc
  security_group_id                = aws_security_group.vm_debug[0].id
  cidr_ipv4                        = "0.0.0.0/0"
  ip_protocol                      = "-1"
  tags                             = merge(local.tags,{Name = "${var.resource_prefixes.aws_vpc_security_group_ingress_rule}-${local.basename}-vmdebug-ingress"})
}

resource "aws_instance" "public" {
  for_each                         = local.create_public_subnets && var.vpc.public.vm_debug ? local.public_subnets : {}
  provider                         = aws.vpc
  ami                              = data.aws_ami.amazon-linux-2.id
  instance_type                    = local.vm_type
  key_name                         = local.vm_ssh_key
  subnet_id                        = aws_subnet.public[each.value.cidr_block].id
  availability_zone                = each.value.availability_zone
  vpc_security_group_ids           = [ aws_security_group.vm_debug[0].id ]
  tags                             = merge(local.tags,{Name = "${var.resource_prefixes.aws_instance}-${local.basename}-vmdebug-${each.value.role}-${each.value.az}"})
}

resource "aws_instance" "private" {
  for_each                         = local.create_private_subnets && var.vpc.private.vm_debug ? local.private_subnets : {}
  provider                         = aws.vpc
  ami                              = data.aws_ami.amazon-linux-2.id
  instance_type                    = local.vm_type
  key_name                         = local.vm_ssh_key
  subnet_id                        = aws_subnet.private[each.value.cidr_block].id
  availability_zone                = each.value.availability_zone
  vpc_security_group_ids           = [ aws_security_group.vm_debug[0].id ]
  tags                             = merge(local.tags,{Name = "${var.resource_prefixes.aws_instance}-${local.basename}-vmdebug-${each.value.role}-${each.value.az}"})
}

resource "aws_instance" "transit" {
  for_each                         = local.create_transit_subnets && var.vpc.transit.vm_debug ? local.transit_subnets : {}
  provider                         = aws.vpc
  ami                              = data.aws_ami.amazon-linux-2.id
  instance_type                    = local.vm_type
  key_name                         = local.vm_ssh_key
  subnet_id                        = aws_subnet.transit[each.value.cidr_block].id
  availability_zone                = each.value.availability_zone
  vpc_security_group_ids           = [ aws_security_group.vm_debug[0].id ]
  tags                             = merge(local.tags,{Name = "${var.resource_prefixes.aws_instance}-${local.basename}-vmdebug-${each.value.role}-${each.value.az}"})
}

################################################################################
# Save to SSM
################################################################################

resource "aws_ssm_parameter" "this" {
  count       = var.vpc.create ? 1 : 0
  provider    = aws.ssm
  name        = "${var.ssm.ssm_path}/${var.ssm.repository_name}/${aws_vpc.this[0].id}.json"
  description = "Configuration item - Do not delete !"
  type        = "String"
  value       = jsonencode(local.output)
  tags        = local.tags
}