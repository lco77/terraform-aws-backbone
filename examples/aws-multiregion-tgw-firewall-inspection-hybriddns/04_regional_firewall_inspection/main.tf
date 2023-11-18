################################################################################
# EUC1
################################################################################

resource "aws_ssm_parameter" "euc1" {
  name        = "${var.ssm_path}/${var.repository_name}/euc1.json"
  description = "Configuration item - Do not delete !"
  type        = "String"
  tier        = "Intelligent-Tiering"
  value       = jsonencode({vpc = module.euc1-vpc.output, appliance = module.euc1-appliance.output})
  tags        = local.tags
}

################################################################################
# EUW1
################################################################################

module euw1-vpc {
    source                 = "./mod_vpc/"
    providers              = { aws = aws.euw1_1234567890 }
    region                 = "euw1"
    data                   = {
        vpc                = local.input
        tgw                = local.tgw
        rtb                = local.rtb
    }
    map_code_to_region     = local.map_code_to_region
    map_region_to_code     = local.map_region_to_code
    resource_prefixes      = local.map_resource_prefixes
    tags                   = local.tags
}

module euw1-appliance {
    source                 = "./mod_appliance/"
    providers              = { aws = aws.euw1_1234567890 }
    data                   = {
      vpc                  = module.euw1-vpc.output
      appliance             = local.input.euw1.appliance
    }
    map_code_to_region     = local.map_code_to_region
    map_region_to_code     = local.map_region_to_code
    resource_prefixes      = local.map_resource_prefixes
    tags                   = local.tags
}

resource "aws_ssm_parameter" "euw1" {
  name        = "${var.ssm_path}/${var.repository_name}/euw1.json"
  description = "Configuration item - Do not delete !"
  type        = "String"
  tier        = "Intelligent-Tiering"
  value       = jsonencode({vpc = module.euw1-vpc.output, appliance = module.euw1-appliance.output})
  tags        = local.tags
}

################################################################################
# USE1
################################################################################

module use1-vpc {
    source                 = "./mod_vpc/"
    providers              = { aws = aws.use1_1234567890 }
    region                 = "use1"
    data                   = {
        vpc                = local.input
        tgw                = local.tgw
        rtb                = local.rtb
    }
    map_code_to_region     = local.map_code_to_region
    map_region_to_code     = local.map_region_to_code
    resource_prefixes      = local.map_resource_prefixes
    tags                   = local.tags
}

module use1-appliance {
    source                 = "./mod_appliance/"
    providers              = { aws = aws.use1_1234567890 }
    data                   = {
      vpc                  = module.use1-vpc.output
      appliance            = local.input.use1.appliance
    }
    map_code_to_region     = local.map_code_to_region
    map_region_to_code     = local.map_region_to_code
    resource_prefixes      = local.map_resource_prefixes
    tags                   = local.tags
}

resource "aws_ssm_parameter" "use1" {
  name        = "${var.ssm_path}/${var.repository_name}/use1.json"
  description = "Configuration item - Do not delete !"
  type        = "String"
  tier        = "Intelligent-Tiering"
  value       = jsonencode({vpc = module.use1-vpc.output, appliance = module.use1-appliance.output})
  tags        = local.tags
}

################################################################################
# SAE1
################################################################################

module sae1-vpc {
    source                 = "./mod_vpc/"
    providers              = { aws = aws.sae1_164334632012 }
    region                 = "sae1"
    data                   = {
        vpc                = local.input
        tgw                = local.tgw
        rtb                = local.rtb
    }
    map_code_to_region     = local.map_code_to_region
    map_region_to_code     = local.map_region_to_code
    resource_prefixes      = local.map_resource_prefixes
    tags                   = local.tags
}
