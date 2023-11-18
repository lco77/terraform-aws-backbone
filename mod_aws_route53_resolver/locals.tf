locals {
    create              = var.vpc.create
    tags                = var.tags
    forwarded_zones     = var.route53.forwarded_zones
    system_zones        = var.route53.system_zones
    hosted_zones        = var.route53.hosted_zones
    forwarders          = { for i,v in var.appliance.eth1: i => v }
    az                  = var.appliance.az
    vpc_id              = var.vpc.vpc_id
    cidr                = var.vpc.cidr
    basename            = var.vpc.basename
    private_subnet_ids  = var.vpc.private_subnet_ids
    public_subnet_ids   = var.vpc.public_subnet_ids
    transit_subnet_ids   = var.vpc.transit_subnet_ids
    map_code_to_region  = var.map_code_to_region
    map_region_to_code  = var.map_region_to_code
}