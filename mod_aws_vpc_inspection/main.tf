
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
# NAT Gateways if dia=true on management subnets
################################################################################
resource "aws_eip" "nat" {
  count                            = local.vpc.create && local.vpc.management.dia ? length(local.vpc.public.cidr) : 0
  domain                           = "vpc"
  tags                             = merge(var.tags,{Name = "${var.resource_prefixes.aws_eip}-${local.basename}-nat-${local.vpc.public.az[count.index]}"})
  depends_on                       = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  count                            = local.vpc.create && local.vpc.management.dia ? length(local.vpc.public.cidr) : 0
  subnet_id                        = aws_subnet.public[count.index].id
  allocation_id                    = aws_eip.nat[count.index].id
  tags                             = merge(var.tags,{Name = "${var.resource_prefixes.aws_nat_gateway}-${local.basename}-${local.vpc.public.az[count.index]}"})
  depends_on                       = [aws_internet_gateway.this]
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
# Management Subnets
################################################################################
resource "aws_subnet" "management" {
  count                            = local.vpc.create ? length(local.vpc.management.cidr) : 0
  availability_zone                = "${lookup(var.map_code_to_region,var.region,"")}${local.vpc.management.az[count.index]}"
  cidr_block                       = local.vpc.management.cidr[count.index]
  vpc_id                           = aws_vpc.this[0].id
  tags                             = merge(var.tags,{Name = "${var.resource_prefixes.aws_subnet}-${local.basename}-management-${local.vpc.management.az[count.index]}"})
}

resource "aws_route_table" "management" {
  count                            = local.vpc.create ? length(local.vpc.management.cidr) : 0
  vpc_id                           = aws_vpc.this[0].id
  tags                             = merge(var.tags,{Name = "${var.resource_prefixes.aws_route_table}-${local.basename}-management-${local.vpc.management.az[count.index]}"})
}

resource "aws_route_table_association" "management" {
  count                            = local.vpc.create ? length(local.vpc.management.cidr) : 0
  subnet_id                        = aws_subnet.management[count.index].id
  route_table_id                   = aws_route_table.management[count.index].id
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
  count                            = local.vpc.create ? length(local.vpc.transit.cidr) : 0
  vpc_id                           = aws_vpc.this[0].id
  tags                             = merge(var.tags,{Name = "${var.resource_prefixes.aws_route_table}-${local.basename}-transit-${local.vpc.private.az[count.index]}"})
}

resource "aws_route_table_association" "transit" {
  count                            = local.vpc.create ? length(local.vpc.transit.cidr) : 0
  subnet_id                        = aws_subnet.transit[count.index].id
  route_table_id                   = aws_route_table.transit[count.index].id
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

resource "aws_ec2_transit_gateway_route_table_association" "this" {
  count                            = local.vpc.create ? 1 : 0
  transit_gateway_attachment_id    = aws_ec2_transit_gateway_vpc_attachment.this[0].id
  transit_gateway_route_table_id   = local.rtb.transit_route_tables[local.vpc.transit.associate]
}

resource "aws_ec2_transit_gateway_route_table_propagation" "this" {
  count                            = local.vpc.create ? length(local.vpc.transit.propagate) : 0
  transit_gateway_attachment_id    = aws_ec2_transit_gateway_vpc_attachment.this[0].id
  transit_gateway_route_table_id   = local.rtb.transit_route_tables[local.vpc.transit.propagate[count.index]]
}

################################################################################
# Gateway Load Balancer
################################################################################
resource "aws_lb" "this" {
  count                            = local.vpc.create ? 1 : 0
  name                             = "${var.resource_prefixes.aws_glb}-${local.basename}-fw"
  load_balancer_type               = "gateway"
  enable_cross_zone_load_balancing = true
  subnets                          = aws_subnet.private[*].id
  tags                             = merge(var.tags, { Name = "${var.resource_prefixes.aws_glb}-${local.basename}-fw" })
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "this" {
  count                            = local.vpc.create ? 1 : 0
  name                             = "${var.resource_prefixes.aws_lb_target_group}-${local.basename}-fw"
  port                             = 6081
  protocol                         = "GENEVE"
  target_type                      = "ip"
  vpc_id                           = aws_vpc.this[0].id
  tags                             = merge(var.tags, { Name = "${var.resource_prefixes.aws_lb_target_group}-${local.basename}-fw" })
  health_check {
    port                           = 22
    protocol                       = "TCP"
  }
}
resource "aws_vpc_endpoint_service" "this" {
  count                            = local.vpc.create ? 1 : 0
  acceptance_required              = false
  gateway_load_balancer_arns       = [aws_lb.this[0].arn]
  tags                             = merge(var.tags, { Name = "${var.resource_prefixes.aws_vpc_endpoint_service}-${local.basename}" })
}

resource "aws_vpc_endpoint" "this" {
  count                            = local.vpc.create ? length(local.vpc.private.cidr) : 0
  service_name                     = aws_vpc_endpoint_service.this[0].service_name
  subnet_ids                       = [aws_subnet.private[count.index].id]
  vpc_endpoint_type                = aws_vpc_endpoint_service.this[0].service_type
  vpc_id                           = aws_vpc.this[0].id
  tags                             = merge(var.tags, { Name = "${var.resource_prefixes.aws_vpc_endpoint}-${local.basename}-private-${local.vpc.private.az[count.index]}" })
}

resource "aws_lb_listener" "this" {
  count                            = local.vpc.create ? 1 : 0
  load_balancer_arn                = aws_lb.this[0].arn
  tags                             = merge(var.tags, { Name = "${var.resource_prefixes.aws_lb_listener}-${local.basename}-fw" })
  default_action {
    target_group_arn               = aws_lb_target_group.this[0].id
    type                           = "forward"
  }
}

################################################################################
# Routing
################################################################################

# IPv4 internet route for firewall's public interface
resource "aws_route" "public_internet_gateway" {
  count                            = local.vpc.create ? 1 : 0
  route_table_id                   = aws_route_table.public[0].id
  destination_cidr_block           = "0.0.0.0/0"
  gateway_id                       = aws_internet_gateway.this[0].id
}

# IPv6 internet route for firewall's public interface
resource "aws_route" "public_internet_gateway_ipv6" {
  count                            = local.vpc.create && local.vpc.dual_stack ? 1 : 0
  route_table_id                   = aws_route_table.public[0].id
  destination_ipv6_cidr_block      = "::/0"
  gateway_id                       = aws_internet_gateway.this[0].id
}

# Route all traffic to GWLB Endpoints
resource "aws_route" "transit_default" {
  count                            = local.vpc.create ? length(aws_vpc_endpoint.this[*].id) : 0
  route_table_id                   = aws_route_table.transit[count.index].id
  destination_cidr_block           = "0.0.0.0/0"
  vpc_endpoint_id                  = aws_vpc_endpoint.this[count.index].id
}

# Route back RFC1918 CIDR to TGW
resource "aws_route" "private_rfc1918" {
  count                            = local.vpc.create ? length(local.rfc1918) : 0
  route_table_id                   = aws_route_table.private[0].id
  destination_cidr_block           = local.rfc1918[count.index]
  transit_gateway_id               = local.tgw.tgw_id
  depends_on                       = [ aws_ec2_transit_gateway_vpc_attachment.this ]
}
resource "aws_route" "management_rfc1918" {
  for_each                         = local.vpc.create ? {
    for e in flatten([
        for i,v in local.vpc.management.cidr: [
            for cidr in local.rfc1918: {
                idx    = i
                cidr   = cidr
                rtb_id = aws_route_table.management[i].id
            }
        ]
    ]): "${e.idx}-${e.cidr}" => {cidr = e.cidr, rtb_id = e.rtb_id}    
  } : {}
  route_table_id                   = each.value.rtb_id
  destination_cidr_block           = each.value.cidr
  transit_gateway_id               = local.tgw.tgw_id
  depends_on                       = [ aws_ec2_transit_gateway_vpc_attachment.this ]
}

# Install NAT-DIA route into management RTB if needed
resource "aws_route" "management_default" {
  count                            = local.vpc.create && local.vpc.management.dia ? length(local.vpc.management.cidr) : 0
  route_table_id                   = aws_route_table.management[count.index].id
  destination_cidr_block           = "0.0.0.0/0"
  nat_gateway_id                   = aws_nat_gateway.this[count.index].id
}

# Inject routes into TGW
resource "aws_ec2_transit_gateway_route" "this" {
  for_each                         = local.vpc.create ? {
    for e in flatten([
        for rtb in keys(local.vpc.advertise_transit_routes): [
            for cidr in local.vpc.advertise_transit_routes[rtb]: {
                cidr   = cidr
                rtb    = rtb
                rtb_id = local.rtb.transit_route_tables[rtb]
            }
        ]
    ]): "${e.rtb}-${e.cidr}" => {cidr = e.cidr, rtb_id = e.rtb_id}
  } : {}
  destination_cidr_block           = each.value.cidr
  transit_gateway_attachment_id    = aws_ec2_transit_gateway_vpc_attachment.this[0].id
  transit_gateway_route_table_id   = each.value.rtb_id
  depends_on                       = [ aws_ec2_transit_gateway_vpc_attachment.this ]
}
