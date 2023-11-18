################################################################################
# 1. Transit gateways
################################################################################

module euw1 {
  source            = "./mod_tgw/"
  providers         = { aws = aws.euw1_1234567890 }
  basename          = local.basename.euw1
  asn               = local.asn.euw1
  cidr              = local.cidr.euw1
  tags              = local.aws_tags
  resource_prefixes = local.map_resource_prefixes
}

module use1 {
  source            = "./mod_tgw/"
  providers         = { aws = aws.use1_1234567890 }
  basename          = local.basename.use1
  asn               = local.asn.use1
  cidr              = local.cidr.use1
  tags              = local.aws_tags
  resource_prefixes = local.map_resource_prefixes
}

locals {
  transit_gateways    = {
    euw1  = merge(local.input.euw1,module.euw1.output)
    use1  = merge(local.input.use1,module.use1.output)
  }
}

################################################################################
# 2. Transit peering attachments
################################################################################

module euw1_attach {
  source              = "./mod_tgw_attach/"
  providers           = { aws = aws.euw1_1234567890 }
  tgw                 = "euw1"
  transit_attach      = local.transit_attach
  transit_gateways    = local.transit_gateways
  map_code_to_region  = local.map_code_to_region
  map_region_to_code  = local.map_region_to_code
  tags                = local.aws_tags
  resource_prefixes   = local.map_resource_prefixes
}

module use1_attach {
  source              = "./mod_tgw_attach/"
  providers           = { aws = aws.use1_1234567890 }
  tgw                 = "use1"
  transit_attach      = local.transit_attach
  transit_gateways    = local.transit_gateways
  map_code_to_region  = local.map_code_to_region
  map_region_to_code  = local.map_region_to_code
  tags                = local.aws_tags
  resource_prefixes   = local.map_resource_prefixes
}

locals {
  transit_attachments = {
    euw1  = module.euw1_attach.output
    use1  = module.use1_attach.output
  }
}

################################################################################
# 3. Transit peering acceptance
################################################################################

module euw1_accept {
  source              = "./mod_tgw_accept/"
  providers           = { aws = aws.euw1_1234567890 }
  tgw                 = "euw1"
  transit_accept      = local.transit_accept
  transit_gateways    = local.transit_gateways
  transit_attachments = local.transit_attachments
  tags                = local.aws_tags
  resource_prefixes   = local.map_resource_prefixes
}

module use1_accept {
  source              = "./mod_tgw_accept/"
  providers           = { aws = aws.use1_1234567890 }
  tgw                 = "use1"
  transit_accept      = local.transit_accept
  transit_gateways    = local.transit_gateways
  transit_attachments = local.transit_attachments
  tags                = local.aws_tags
  resource_prefixes   = local.map_resource_prefixes
}

locals {
  transit_accepters = {
    euw1  = module.euw1_accept.output
    use1  = module.use1_accept.output
  }
}

################################################################################
# 4. Transit gateway route tables
################################################################################

module euw1_routing {
  source              = "./mod_tgw_routing/"
  providers           = { aws = aws.euw1_1234567890 }
  tgw                 = "euw1"
  transit_gateways    = local.transit_gateways
  transit_attachments = local.transit_attachments
  transit_accepters   = local.transit_accepters
  tags                = local.aws_tags
  resource_prefixes   = local.map_resource_prefixes
}

module use1_routing {
  source              = "./mod_tgw_routing/"
  providers           = { aws = aws.use1_1234567890 }
  tgw                 = "use1"
  transit_gateways    = local.transit_gateways
  transit_attachments = local.transit_attachments
  transit_accepters   = local.transit_accepters
  tags                = local.aws_tags
  resource_prefixes   = local.map_resource_prefixes
}

locals {
  transit_routing = {
    euw1 = module.euw1_routing.output
    use1 = module.use1_routing.output
  }
}

################################################################################
# 5. Export config (default provider)
################################################################################

resource "aws_ssm_parameter" "transit_gateways" {
  name        = "${var.ssm_path}/transit_gateways.json"
  description = "Configuration item - Do not delete !"
  type        = "String"
  tier        = "Intelligent-Tiering"
  value       = jsonencode(local.transit_gateways)
  tags        = local.aws_tags
}

resource "aws_ssm_parameter" "transit_routing" {
  name        = "${var.ssm_path}/transit_routing.json"
  description = "Configuration item - Do not delete !"
  type        = "String"
  tier        = "Intelligent-Tiering"
  value       = jsonencode(local.transit_routing)
  tags        = local.aws_tags
}
################################################################################
# 6. Network manager
################################################################################

# Create global network
resource "aws_networkmanager_global_network" "this" {
  provider    = aws.euw1_1234567890
  description = "Global network"
}

# Register transit gateways
resource "aws_networkmanager_transit_gateway_registration" "this" {
  provider    = aws.euw1_1234567890
  for_each = local.transit_gateways
  global_network_id   = aws_networkmanager_global_network.this.id
  transit_gateway_arn = each.value.tgw_arn
}

# Subscribe to inter-region metrics
resource "aws_vpc_network_performance_metric_subscription" "this" {
    provider    = aws.euw1_1234567890
    for_each = nonsensitive({
    for e in flatten([
      for src in keys(local.transit_routing): [
        for k,v in local.transit_routing[src].transit_peering_map: {
          src = local.map_code_to_region[src]
          dst = local.map_code_to_region[split("-",k)[1]]
        }
      ]
    ]): "${e.src}_${e.dst}" => {src = e.src, dst = e.dst}
  })
  source      = each.value.src
  destination = each.value.dst
}

################################################################################
# 7. RAM accepters for legacy accounts - get RAM share data before using it
# See also jinja-ram-accepters.tf
################################################################################

data "aws_ram_resource_share" "euw1" {
  provider       = aws.euw1_1234567890
  name           = "${local.map_resource_prefixes.aws_ram_resource_share}-tgw-euw1-prd-transit-001"
  resource_owner = "SELF"
}

data "aws_ram_resource_share" "use1" {
  provider       = aws.use1_1234567890
  name           = "${local.map_resource_prefixes.aws_ram_resource_share}-tgw-use1-prd-transit-001"
  resource_owner = "SELF"
}

