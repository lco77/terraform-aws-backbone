locals {
    tags                = var.tags
    zones               = var.zones
    vpcs                = { for i,v in var.vpcs: v.fullname => {id = v.vpc_id, region = v.region} }
    map_code_to_region  = var.map_code_to_region
    map_region_to_code  = var.map_region_to_code
}