locals {
    basename               = "${var.vpc.region}-${var.vpc.environment}-${var.vpc.name}-${var.vpc.release}"
    create_public_subnets  = var.vpc.create && var.vpc.public  != {}
    create_private_subnets = var.vpc.create && var.vpc.private != {}
    create_transit_subnets = var.vpc.create && var.vpc.transit != {}
    rfc1918                = ["10.0.0.0/8","172.16.0.0/12","192.168.0.0/16"]
    vm_type                = "t4g.nano"
    vm_ssh_key             = "nws_systems"
}