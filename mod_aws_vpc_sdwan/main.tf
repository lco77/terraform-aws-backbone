
################################################################################
# VPC
################################################################################
resource "aws_vpc" "this" {
  count                            = local.vpc.create ? 1 : 0
  cidr_block                       = local.vpc.cidr
  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = local.vpc.dual_stack
  tags                             = merge(var.tags,{Name = "${var.resource_prefixes.aws_vpc}-${local.basename}"})
}

################################################################################
# Internet Gateway
################################################################################
resource "aws_internet_gateway" "this" {
  count                            = local.vpc.create ? 1 : 0
  vpc_id                           = aws_vpc.this[0].id
  tags                             = merge(var.tags,{Name = "${var.resource_prefixes.aws_internet_gateway}-${local.basename}"})
}

resource "aws_egress_only_internet_gateway" "this" {
  count                            = local.vpc.create && local.vpc.dual_stack ? 1 : 0
  vpc_id                           = aws_vpc.this[0].id
  tags                             = merge(var.tags,{Name = "${var.resource_prefixes.aws_egress_only_internet_gateway}-${local.basename}"})
}

################################################################################
# Publiс Subnets
################################################################################
resource "aws_subnet" "public" {
  count                            = local.vpc.create ? length(local.vpc.public.cidr) : 0
  assign_ipv6_address_on_creation  = true
  availability_zone                = "${lookup(var.map_code_to_region,var.region,"")}${local.vpc.public.az[count.index]}"
  cidr_block                       = local.vpc.public.cidr[count.index]
  ipv6_cidr_block                  = cidrsubnet(aws_vpc.this[0].ipv6_cidr_block, 8, count.index)
  vpc_id                           = aws_vpc.this[0].id
  tags                             = merge(var.tags,{Name = "${var.resource_prefixes.aws_subnet}-${local.basename}-public-${local.vpc.public.az[count.index]}"})
}

resource "aws_route_table" "public" {
  count                            = local.vpc.create ? 1 : 0
  vpc_id                           = aws_vpc.this[0].id
  tags                             = merge(var.tags,{Name = "${var.resource_prefixes.aws_route_table}-${local.basename}-public"})
}

resource "aws_route_table_association" "public" {
  count                            = local.vpc.create ? length(local.vpc.public.cidr) : 0
  subnet_id                        = aws_subnet.public[count.index].id
  route_table_id                   = aws_route_table.public[0].id
}

################################################################################
# Private Subnets
################################################################################
resource "aws_subnet" "private" {
  count                            = local.vpc.create ? length(local.vpc.private.cidr) : 0
  availability_zone                = "${lookup(var.map_code_to_region,var.region,"")}${local.vpc.private.az[count.index]}"
  cidr_block                       = local.vpc.private.cidr[count.index]
  vpc_id                           = aws_vpc.this[0].id
  tags                             = merge(var.tags,{Name = "${var.resource_prefixes.aws_subnet}-${local.basename}-private-${local.vpc.private.az[count.index]}"})
}

resource "aws_route_table" "private" {
  count                            = local.vpc.create ? 1 : 0
  vpc_id                           = aws_vpc.this[0].id
  tags                             = merge(var.tags,{Name = "${var.resource_prefixes.aws_route_table}-${local.basename}-private"})
}

resource "aws_route_table_association" "private" {
  count                            = local.vpc.create ? length(local.vpc.private.cidr) : 0
  subnet_id                        = aws_subnet.private[count.index].id
  route_table_id                   = aws_route_table.private[0].id
}

################################################################################
# Transit Gateway Subnets
################################################################################
resource "aws_subnet" "transit" {
  count                            = local.vpc.create ? length(local.vpc.transit.cidr) : 0
  availability_zone                = "${lookup(var.map_code_to_region,var.region,"")}${local.vpc.transit.az[count.index]}"
  cidr_block                       = local.vpc.transit.cidr[count.index]
  vpc_id                           = aws_vpc.this[0].id
  tags                             = merge(var.tags,{Name = "${var.resource_prefixes.aws_subnet}-${local.basename}-transit-${local.vpc.transit.az[count.index]}"})
}

resource "aws_route_table" "transit" {
  count                            = local.vpc.create ? 1 : 0
  vpc_id                           = aws_vpc.this[0].id
  tags                             = merge(var.tags,{Name = "${var.resource_prefixes.aws_route_table}-${local.basename}-transit"})
}

resource "aws_route_table_association" "transit" {
  count                            = local.vpc.create ? length(local.vpc.transit.cidr) : 0
  subnet_id                        = aws_subnet.transit[count.index].id
  route_table_id                   = aws_route_table.transit[0].id
}

################################################################################
# Transit Attachment
################################################################################
resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  count                            = local.vpc.create ? 1 : 0
  subnet_ids                       = aws_subnet.transit[*].id
  transit_gateway_id               = local.tgw.tgw_id
  vpc_id                           = aws_vpc.this[0].id
  appliance_mode_support           = "enable"
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  tags                             = merge(var.tags,{Name = "${var.resource_prefixes.aws_ec2_transit_gateway_vpc_attachment}-${local.basename}"})
}

resource "aws_ec2_transit_gateway_connect" "this" {
  count                            = local.vpc.create ? 1 : 0
  transport_attachment_id          = aws_ec2_transit_gateway_vpc_attachment.this[0].id
  transit_gateway_id               = local.tgw.tgw_id
  tags                             = merge(var.tags,{Name = "${var.resource_prefixes.aws_ec2_transit_gateway_connect}-${local.basename}"})
}

resource "aws_ec2_transit_gateway_route_table_association" "connect" {
  count                            = local.vpc.create ? 1 : 0
  transit_gateway_attachment_id    = aws_ec2_transit_gateway_connect.this[0].id
  transit_gateway_route_table_id   = local.rtb.transit_route_tables[local.vpc.transit.associate]
}

resource "aws_ec2_transit_gateway_route_table_propagation" "connect" {
  count                            = local.vpc.create ? length(local.vpc.transit.propagate) : 0
  transit_gateway_attachment_id    = aws_ec2_transit_gateway_connect.this[0].id
  transit_gateway_route_table_id   = local.rtb.transit_route_tables[local.vpc.transit.propagate[count.index]]
}

################################################################################
# Routing
################################################################################

# IPv4 internet route for router's public interface
resource "aws_route" "public_internet_gateway" {
  count                            = local.vpc.create ? 1 : 0
  route_table_id                   = aws_route_table.public[0].id
  destination_cidr_block           = "0.0.0.0/0"
  gateway_id                       = aws_internet_gateway.this[0].id
}

# IPv6 internet route for router's public interface
resource "aws_route" "public_internet_gateway_ipv6" {
  count                            = local.vpc.create ? 1 : 0
  route_table_id                   = aws_route_table.public[0].id
  destination_ipv6_cidr_block      = "::/0"
  gateway_id                       = aws_internet_gateway.this[0].id
}

# Private route to TGW Connect CIDR
resource "aws_route" "private_tgw_connect" {
  count                            = local.vpc.create ? 1 : 0
  route_table_id                   = aws_route_table.private[0].id
  destination_cidr_block           = local.tgw.cidr
  transit_gateway_id               = local.tgw.tgw_id
}