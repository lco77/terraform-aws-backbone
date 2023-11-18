################################################################################
# 1. Create Core Services VPCs
################################################################################

module vpc_euw1 {
    source    = "./mod_vpc/"
    providers = {
        aws.vpc = aws.euw1_1234567890
        aws.tgw = aws.euw1_1234567890
        }
    vpc                = local.config.euw1.vpc
    tgw                = local.tgw.euw1
    rtb                = local.rtb.euw1
    tags               = merge(local.aws_tags,local.config.euw1.tags) 
    map_code_to_region = local.map_code_to_region
    map_region_to_code = local.map_region_to_code
    resource_prefixes  = local.map_resource_prefixes
}

module vpc_use1 {
    source    = "./mod_vpc/"
    providers = {
        aws.vpc = aws.use1_1234567890
        aws.tgw = aws.use1_1234567890
        }
    vpc                = local.config.use1.vpc
    tgw                = local.tgw.use1
    rtb                = local.rtb.use1
    tags               = merge(local.aws_tags,local.config.use1.tags) 
    map_code_to_region = local.map_code_to_region
    map_region_to_code = local.map_region_to_code
    resource_prefixes  = local.map_resource_prefixes
}

################################################################################
# 2. Create Route53 private zone and associate with core VPCs
# Note that we use "us-east-1" region here
################################################################################

# Primary DNS domain for this landing zone
module domain {
  source             = "./mod_route53_domain/"
  providers          = { aws = aws.use1_1234567890 }
  tags               = local.aws_tags
  vpcs               = {
    euw1             = module.vpc_euw1.output
    use1             = module.vpc_use1.output
  }
  domain             = local.config.global_settings.route53.domain
  map_code_to_region = local.map_code_to_region
  map_region_to_code = local.map_region_to_code
  resource_prefixes  = local.map_resource_prefixes
}

# Additional domains (optional)
module hosted_zones {
  source             = "./mod_route53_hosted_zones/"
  providers          = { aws = aws.use1_1234567890 }
  tags               = local.aws_tags
  vpcs               = {
    euw1             = module.vpc_euw1.output
    use1             = module.vpc_use1.output
  }
  zones              = local.config.global_settings.route53.hosted_zones
  map_code_to_region = local.map_code_to_region
  map_region_to_code = local.map_region_to_code
  resource_prefixes  = local.map_resource_prefixes
}

################################################################################
# 3. Create Infoblox appliances
################################################################################

module grid_member_euw1 {
    source             = "./mod_grid_member/"
    providers          = { aws = aws.euw1_1234567890 }
    appliance          = local.config.euw1.appliance
    vpc                = module.vpc_euw1.output
    tags               = merge(local.aws_tags,local.config.euw1.tags)
    map_code_to_region = local.map_code_to_region
    map_region_to_code = local.map_region_to_code
    resource_prefixes  = local.map_resource_prefixes
}

module grid_member_use1 {
    source             = "./mod_grid_member/"
    providers          = { aws = aws.use1_1234567890 }
    appliance          = local.config.use1.appliance
    vpc                = module.vpc_use1.output
    tags               = merge(local.aws_tags,local.config.use1.tags)
    map_code_to_region = local.map_code_to_region
    map_region_to_code = local.map_region_to_code
    resource_prefixes  = local.map_resource_prefixes
}

################################################################################
# 4. Create shared route53 resolver rules and associated resolver endpoints
################################################################################

module route53_euw1 {
    source             = "./mod_route53_resolver/"
    providers          = { aws = aws.euw1_1234567890 }
    route53            = local.config.global_settings.route53
    appliance          = module.grid_member_euw1.output
    vpc                = module.vpc_euw1.output
    tags               = merge(local.aws_tags,local.config.euw1.tags)
    map_code_to_region = local.map_code_to_region
    map_region_to_code = local.map_region_to_code
    resource_prefixes  = local.map_resource_prefixes
}

module route53_use1 {
    source             = "./mod_route53_resolver/"
    providers          = { aws = aws.use1_1234567890 }
    route53            = local.config.global_settings.route53
    appliance          = module.grid_member_use1.output
    vpc                = module.vpc_use1.output
    tags               = merge(local.aws_tags,local.config.use1.tags)
    map_code_to_region = local.map_code_to_region
    map_region_to_code = local.map_region_to_code
    resource_prefixes  = local.map_resource_prefixes
}

################################################################################
# 5. Output results into parameter store
################################################################################

resource "aws_ssm_parameter" "euw1" {
  name               = "${var.ssm_path}/dns/euw1.json"
  description        = "Configuration item - Do not delete !"
  type               = "String"
  tier               = "Intelligent-Tiering"
  value              = jsonencode({
    vpc              = module.vpc_euw1.output
    appliance        = module.grid_member_euw1.output
    route53_domain   = module.domain.output
    route53_resolver = module.route53_euw1.output
    route53_zones    = module.hosted_zones.output
  })
  tags        = local.aws_tags
}

resource "aws_ssm_parameter" "use1" {
  name               = "${var.ssm_path}/dns/use1.json"
  description        = "Configuration item - Do not delete !"
  type               = "String"
  tier               = "Intelligent-Tiering"
  value              = jsonencode({
    vpc              = module.vpc_use1.output
    appliance        = module.grid_member_use1.output
    route53_domain   = module.domain.output
    route53_resolver = module.route53_use1.output
    route53_zones    = module.hosted_zones.output
  })
  tags        = local.aws_tags
}

################################################################################
# 6. RAM accepters for legacy accounts
# Accounts outside the organization must accept the RAM share
# See also "jinja-ram-accepters.tf"
################################################################################

# Read RAM share to make sure it is available before accepting it
data "aws_ram_resource_share" "euw1" {
  provider       = aws.euw1_1234567890
  name           = "${local.map_resource_prefixes.aws_ram_resource_share}-rslvr-rr-euw1-prd-core-001"
  resource_owner = "SELF"
  depends_on     = [ module.route53_euw1 ]
}

data "aws_ram_resource_share" "use1" {
  provider       = aws.use1_1234567890
  name           = "${local.map_resource_prefixes.aws_ram_resource_share}-rslvr-rr-use1-prd-core-001"
  resource_owner = "SELF"
  depends_on     = [ module.route53_use1 ]
}
