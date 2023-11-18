
# Create transit gateway
resource "aws_ec2_transit_gateway" "this" {
  description                     = var.basename
  amazon_side_asn                 = var.asn
  auto_accept_shared_attachments  = "disable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  dns_support                     = "enable"
  multicast_support               = "disable"
  transit_gateway_cidr_blocks     = [var.cidr]
  vpn_ecmp_support                = "enable"
  tags                            = merge(var.tags, {Name = "${var.resource_prefixes.aws_ec2_transit_gateway}-${var.basename}"})
}

# Create resource share
resource "aws_ram_resource_share" "this" {
  name = "${var.resource_prefixes.aws_ram_resource_share}-tgw-${var.basename}"
  allow_external_principals = true
  tags = merge(var.tags, {Name = "${var.resource_prefixes.aws_ram_resource_share}-tgw-${var.basename}"})
}

# Share the transit gateway
resource "aws_ram_resource_association" "this" {
  resource_arn       = aws_ec2_transit_gateway.this.arn
  resource_share_arn = aws_ram_resource_share.this.id
}
