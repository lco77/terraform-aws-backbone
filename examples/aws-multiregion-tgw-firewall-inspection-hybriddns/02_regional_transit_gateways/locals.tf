locals {
    aws_tags              = merge(jsondecode(data.aws_ssm_parameter.aws_tags.value),{Reference = var.repository_uri})
    map_code_to_region    = jsondecode(data.aws_ssm_parameter.map_code_to_region.value)
    map_region_to_code    = jsondecode(data.aws_ssm_parameter.map_region_to_code.value)
    map_resource_prefixes = jsondecode(data.aws_ssm_parameter.map_resource_prefixes.value)
    input                 = jsondecode(file(var.input_file))
    basename              = {for k,v in local.input: k => "${v.region}-${v.environment}-${v.name}-${v.release}"}
    region                = {for k,v in local.input: k => v.region}
    asn                   = {for k,v in local.input: k => v.asn}
    cidr                  = {for k,v in local.input: k => v.cidr}
    principals            = {for k,v in local.input: k => v.ram_principals}
    transit_attach        = {for k,v in local.input: k => v.transit_attach}
    transit_accept        = {for k,v in local.input: k => v.transit_accept}
    transit_domain_ipv4   = {for k,v in local.input: k => v.transit_domain_ipv4}
}