locals {
    config                = jsondecode(file(var.input_file))
    aws_tags              = jsondecode(data.aws_ssm_parameter.aws_tags.value)
    map_code_to_region    = jsondecode(data.aws_ssm_parameter.map_code_to_region.value)
    map_region_to_code    = jsondecode(data.aws_ssm_parameter.map_region_to_code.value)
    map_resource_prefixes = jsondecode(data.aws_ssm_parameter.map_resource_prefixes.value)
    tgw                   = jsondecode(data.aws_ssm_parameter.transit_gateways.value)
    rtb                   = jsondecode(data.aws_ssm_parameter.transit_routing.value)
}
