locals {
    tags                = var.tags
    create              = var.appliance.create
    ssh_key             = var.appliance.ssh_key
    instance_type       = var.appliance.instance_type
    user_data           = var.appliance.user_data
    az                  = var.appliance.az
    vpc_id              = var.vpc.vpc_id
    basename            = var.vpc.basename
    private_subnet_ids  = var.vpc.private_subnet_ids
    public_subnet_ids   = var.vpc.public_subnet_ids
}