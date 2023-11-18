
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
  tags                             = merge(var.tags,{Name = "${var.resource_prefixes.aws_vpc}-${local.basename}"})
}

################################################################################
# Internet Gateway
################################################################################
resource "aws_internet_gateway" "this" {
  count                            = local.create_public_subnets && var.vpc.public.dia ? 1 : 0
  provider                         = aws.vpc
  vpc_id                           = aws_vpc.this[0].id
  tags                             = merge(var.tags,{Name = "${var.resource_prefixes.aws_internet_gateway}-${local.basename}"})
}

resource "aws_egress_only_internet_gateway" "this" {
  count                            = local.create_public_subnets && var.vpc.public.dia && var.vpc.dual_stack ? 1 : 0
  provider                         = aws.vpc
  vpc_id                           = aws_vpc.this[0].id
  tags                             = merge(var.tags,{Name = "${var.resource_prefixes.aws_egress_only_internet_gateway}-${local.basename}"})
}

################################################################################
# NAT Gateway
################################################################################
resource "aws_eip" "nat" {
  count                            = local.create_public_subnets && local.create_private_subnets && var.vpc.public.dia && var.vpc.private.dia ? length(var.vpc.private.cidr) : 0
  provider                         = aws.vpc
  domain                           = "vpc"
  tags                             = merge(var.tags,{Name = "${var.resource_prefixes.aws_eip}-${local.basename}-nat-${var.vpc.public.az[count.index]}"})
  depends_on                       = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  count                            = local.create_public_subnets && local.create_private_subnets && var.vpc.public.dia && var.vpc.private.dia ? length(var.vpc.private.cidr) : 0
  provider                         = aws.vpc
  subnet_id                        = aws_subnet.public[count.index].id
  allocation_id                    = aws_eip.nat[count.index].id
  tags                             = merge(var.tags,{Name = "${var.resource_prefixes.aws_nat_gateway}-${local.basename}-${var.vpc.public.az[count.index]}"})
  depends_on                       = [aws_internet_gateway.this]
}

################################################################################
# Publiс Subnets
################################################################################
resource "aws_subnet" "public" {
  count                            = local.create_public_subnets ? length(var.vpc.public.cidr) : 0
  provider                         = aws.vpc
  assign_ipv6_address_on_creation  = var.vpc.dual_stack
  availability_zone                = "${lookup(var.map_code_to_region,var.vpc.region,"")}${var.vpc.public.az[count.index]}"
  cidr_block                       = var.vpc.public.cidr[count.index]
  ipv6_cidr_block                  = var.vpc.dual_stack ? cidrsubnet(aws_vpc.this[0].ipv6_cidr_block, 8, count.index) : null
  vpc_id                           = aws_vpc.this[0].id
  tags                             = merge(var.tags,{Name = "${var.resource_prefixes.aws_subnet}-${local.basename}-public-${var.vpc.public.az[count.index]}"})
}

resource "aws_route_table" "public" {
  count                            = local.create_public_subnets ? 1 : 0
  provider                         = aws.vpc
  vpc_id                           = aws_vpc.this[0].id
  tags                             = merge(var.tags,{Name = "${var.resource_prefixes.aws_route_table}-${local.basename}-public"})
}

resource "aws_route_table_association" "public" {
  count                            = local.create_public_subnets ? length(var.vpc.public.cidr) : 0
  provider                         = aws.vpc
  subnet_id                        = element(aws_subnet.public[*].id, count.index)
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
  count                            = local.create_private_subnets ? length(var.vpc.private.cidr) : 0
  provider                         = aws.vpc
  availability_zone                = "${lookup(var.map_code_to_region,var.vpc.region,"")}${var.vpc.private.az[count.index]}"
  cidr_block                       = var.vpc.private.cidr[count.index]
  vpc_id                           = aws_vpc.this[0].id
  tags                             = merge(var.tags,{Name = "${var.resource_prefixes.aws_subnet}-${local.basename}-private-${var.vpc.private.az[count.index]}"})
}

resource "aws_route_table" "private" {
  count                            = local.create_private_subnets && !var.vpc.private.dia ? 1 : 0
  provider                         = aws.vpc
  vpc_id                           = aws_vpc.this[0].id
  tags                             = merge(var.tags,{Name = "${var.resource_prefixes.aws_route_table}-${local.basename}-private"})
}

resource "aws_route_table" "private_with_nat" {
  count                            = local.create_private_subnets && var.vpc.private.dia ? length(var.vpc.private.cidr) : 0
  provider                         = aws.vpc
  vpc_id                           = aws_vpc.this[0].id
  tags                             = merge(var.tags,{Name = "${var.resource_prefixes.aws_route_table}-${local.basename}-private-${var.vpc.private.az[count.index]}"})
}

resource "aws_route_table_association" "private" {
  count                            = local.create_private_subnets && !var.vpc.private.dia ? length(var.vpc.private.cidr) : 0
  provider                         = aws.vpc
  subnet_id                        = aws_subnet.private[count.index].id
  route_table_id                   = aws_route_table.private[0].id
}

resource "aws_route_table_association" "private_with_nat" {
  count                            = local.create_private_subnets && var.vpc.private.dia ? length(var.vpc.private.cidr) : 0
  provider                         = aws.vpc
  subnet_id                        = aws_subnet.private[count.index].id
  route_table_id                   = aws_route_table.private_with_nat[count.index].id
}

resource "aws_route" "nat_gateway" {
  count                            = local.create_private_subnets && var.vpc.private.dia ? length(var.vpc.private.cidr) : 0
  provider                         = aws.vpc
  route_table_id                   = aws_route_table.private_with_nat[count.index].id
  destination_cidr_block           = "0.0.0.0/0"
  nat_gateway_id                   = aws_nat_gateway.this[count.index].id
}

################################################################################
# Transit Gateway Subnets
################################################################################
resource "aws_subnet" "transit" {
  count                            = local.create_transit_subnets ? length(var.vpc.transit.cidr) : 0
  provider                         = aws.vpc
  availability_zone                = "${lookup(var.map_code_to_region,var.vpc.region,"")}${var.vpc.transit.az[count.index]}"
  cidr_block                       = var.vpc.transit.cidr[count.index]
  vpc_id                           = aws_vpc.this[0].id
  tags                             = merge(var.tags,{Name = "${var.resource_prefixes.aws_subnet}-${local.basename}-transit-${var.vpc.transit.az[count.index]}"})
}

resource "aws_route_table" "transit" {
  count                            = local.create_transit_subnets ? 1 : 0
  provider                         = aws.vpc
  vpc_id                           = aws_vpc.this[0].id
  tags                             = merge(var.tags,{Name = "${var.resource_prefixes.aws_route_table}-${local.basename}-transit"})
}

resource "aws_route_table_association" "transit" {
  count                            = local.create_transit_subnets ? length(var.vpc.transit.cidr) : 0
  provider                         = aws.vpc
  subnet_id                        = aws_subnet.transit[count.index].id
  route_table_id                   = aws_route_table.transit[0].id
}

################################################################################
# Transit Attachment
################################################################################
resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  count                            = var.vpc.create && var.vpc.transit != {} ? 1 : 0
  provider                         = aws.vpc
  subnet_ids                       = aws_subnet.transit[*].id
  transit_gateway_id               = var.tgw.tgw_id
  vpc_id                           = aws_vpc.this[0].id
  appliance_mode_support           = "enable"
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  tags                             = merge(var.tags,{Name = "${var.resource_prefixes.aws_ec2_transit_gateway_vpc_attachment}-${local.basename}"})
}

# resource "aws_ec2_transit_gateway_vpc_attachment_accepter" "this" {
#   count                            = var.create && var.vpc.transit != {} && lookup({for k,v in var.tgw: v.region => v.account},var.region,"") != var.account ? 1 : 0
#   provider                         = aws.tgw
#   transit_gateway_attachment_id    = aws_ec2_transit_gateway_vpc_attachment.this[0].id
#   tags                             = merge(var.tags,{Name = "tgw-accept-${local.basename}"})
# }

resource "aws_ec2_transit_gateway_route_table_association" "this" {
  count                            = var.vpc.create && var.vpc.transit != {} ? 1 : 0
  provider                         = aws.tgw
  transit_gateway_attachment_id    = aws_ec2_transit_gateway_vpc_attachment.this[0].id
  transit_gateway_route_table_id   = var.rtb.transit_route_tables[var.vpc.transit.associate]
}

resource "aws_ec2_transit_gateway_route_table_propagation" "this" {
  count                            = var.vpc.create && var.vpc.transit != {} ? length(var.vpc.transit.propagate) : 0
  provider                         = aws.tgw
  transit_gateway_attachment_id    = aws_ec2_transit_gateway_vpc_attachment.this[0].id
  transit_gateway_route_table_id   = var.rtb.transit_route_tables[var.vpc.transit.propagate[count.index]]
}

################################################################################
# Transit Routing
################################################################################
resource "aws_route" "transit_default" {
  count                            = local.create_transit_subnets && var.vpc.transit != {} ? 1 : 0
  provider                         = aws.vpc
  route_table_id                   = aws_route_table.transit[0].id
  destination_cidr_block           = "0.0.0.0/0"
  transit_gateway_id               = var.tgw.tgw_id
  depends_on                       = [ aws_ec2_transit_gateway_vpc_attachment.this ]
}

resource "aws_route" "private_default" {
  count                            = local.create_private_subnets && !var.vpc.private.dia && var.vpc.transit != {} ? 1 : 0
  provider                         = aws.vpc
  route_table_id                   = aws_route_table.private[0].id
  destination_cidr_block           = "0.0.0.0/0"
  transit_gateway_id               = var.tgw.tgw_id
  depends_on                       = [ aws_ec2_transit_gateway_vpc_attachment.this ]
}

resource "aws_route" "private_rfc1918" {
  for_each = local.create_private_subnets && var.vpc.private.dia && var.vpc.transit != {} ? {
    for e in flatten([
      for cidr in local.rfc1918: [
        for i,v in var.vpc.private.cidr: {
          cidr  = cidr
          index = i
        }
      ]
    ]): "${e.cidr}_${e.index}" => {cidr = e.cidr, rtb = aws_route_table.private_with_nat[e.index].id}
  } : {}
  provider                         = aws.vpc
  route_table_id                   = each.value.rtb
  destination_cidr_block           = each.value.cidr
  transit_gateway_id               = var.tgw.tgw_id
  depends_on                       = [ aws_ec2_transit_gateway_vpc_attachment.this ]
}

resource "aws_route" "public_rfc1918" {
  for_each = local.create_public_subnets && var.vpc.public.rfc1918_routes && var.vpc.transit != {} ? { for i,v in local.rfc1918: i=>v}  : {}
  provider                         = aws.vpc
  route_table_id                   = aws_route_table.public[0].id
  destination_cidr_block           = each.value
  transit_gateway_id               = var.tgw.tgw_id
  depends_on                       = [ aws_ec2_transit_gateway_vpc_attachment.this ]
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
  tags                             = merge(var.tags,{Name = "${var.resource_prefixes.aws_security_group}-${local.basename}-vmdebug"})
}

resource "aws_vpc_security_group_egress_rule" "vm_debug" {
  count                            = (local.create_public_subnets || local.create_private_subnets || local.create_transit_subnets) && (var.vpc.public.vm_debug ||  var.vpc.private.vm_debug || var.vpc.transit.vm_debug) ? 1 : 0
  provider                         = aws.vpc
  security_group_id                = aws_security_group.vm_debug[0].id
  cidr_ipv4                        = "0.0.0.0/0"
  ip_protocol                      = "-1"
  tags                             = merge(var.tags,{Name = "${var.resource_prefixes.aws_vpc_security_group_egress_rule}-${local.basename}-vmdebug-egress"})
}

resource "aws_vpc_security_group_ingress_rule" "vm_debug" {
  count                            = (local.create_public_subnets || local.create_private_subnets || local.create_transit_subnets) && (var.vpc.public.vm_debug ||  var.vpc.private.vm_debug || var.vpc.transit.vm_debug) ? 1 : 0
  provider                         = aws.vpc
  security_group_id                = aws_security_group.vm_debug[0].id
  cidr_ipv4                        = "0.0.0.0/0"
  ip_protocol                      = "-1"
  tags                             = merge(var.tags,{Name = "${var.resource_prefixes.aws_vpc_security_group_ingress_rule}-${local.basename}-vmdebug-ingress"})
}

resource "aws_instance" "public" {
  count                            = local.create_public_subnets && var.vpc.public.vm_debug ? length(var.vpc.public.cidr) : 0
  provider                         = aws.vpc
  ami                              = data.aws_ami.amazon-linux-2.id
  instance_type                    = local.vm_type
  key_name                         = local.vm_ssh_key
  subnet_id                        = aws_subnet.public[count.index].id
  availability_zone                = "${lookup(var.map_code_to_region,var.vpc.region,"")}${var.vpc.public.az[count.index]}"
  vpc_security_group_ids           = [ aws_security_group.vm_debug[0].id ]
  tags                             = merge(var.tags,{Name = "${var.resource_prefixes.aws_instance}-${local.basename}-vmdebug-public-${var.vpc.public.az[count.index]}"})
}

resource "aws_instance" "private" {
  count                            = local.create_private_subnets && var.vpc.private.vm_debug ? length(var.vpc.private.cidr) : 0
  provider                         = aws.vpc
  ami                              = data.aws_ami.amazon-linux-2.id
  instance_type                    = local.vm_type
  key_name                         = local.vm_ssh_key
  subnet_id                        = aws_subnet.private[count.index].id
  availability_zone                = "${lookup(var.map_code_to_region,var.vpc.region,"")}${var.vpc.private.az[count.index]}"
  vpc_security_group_ids           = [ aws_security_group.vm_debug[0].id ]
  tags                             = merge(var.tags,{Name = "${var.resource_prefixes.aws_instance}-${local.basename}-vmdebug-private-${var.vpc.private.az[count.index]}"})
}

resource "aws_instance" "transit" {
  count                            = local.create_transit_subnets && var.vpc.transit.vm_debug ? length(var.vpc.transit.cidr) : 0
  provider                         = aws.vpc
  ami                              = data.aws_ami.amazon-linux-2.id
  instance_type                    = local.vm_type
  key_name                         = local.vm_ssh_key
  subnet_id                        = aws_subnet.transit[count.index].id
  availability_zone                = "${lookup(var.map_code_to_region,var.vpc.region,"")}${var.vpc.transit.az[count.index]}"
  vpc_security_group_ids           = [ aws_security_group.vm_debug[0].id ]
  tags                             = merge(var.tags,{Name = "${var.resource_prefixes.aws_instance}-${local.basename}-vmdebug-transit-${var.vpc.transit.az[count.index]}"})
}