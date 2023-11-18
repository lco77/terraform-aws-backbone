locals {
    tags                  = merge(jsondecode(data.aws_ssm_parameter.aws_tags.value),{Reference = var.repository_uri})
    map_code_to_region    = jsondecode(data.aws_ssm_parameter.map_code_to_region.value)
    map_region_to_code    = jsondecode(data.aws_ssm_parameter.map_region_to_code.value)
    map_resource_prefixes = jsondecode(data.aws_ssm_parameter.map_resource_prefixes.value)
    tgw                   = jsondecode(data.aws_ssm_parameter.transit_gateways.value)
    rtb                   = jsondecode(data.aws_ssm_parameter.transit_routing.value)
    ssm                   = {
        ssm_path = var.ssm_path
        repository_name = var.repository_name
    }
    core                  = {
        euw1              = jsondecode(data.aws_ssm_parameter.aws_core_euw1.value)
        use1              = jsondecode(data.aws_ssm_parameter.aws_core_use1.value)
    }
    # Assets
    fileset = fileset(path.module, "assets/*.json")
    config  = { for k,v in data.local_file.assets: k => jsondecode(v.content) }
}