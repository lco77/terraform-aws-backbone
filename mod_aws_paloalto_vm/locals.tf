locals {
    create    = var.data.vpc.create
    basename  = var.data.vpc.basename
    vpc       = var.data.vpc
    fw        = var.data.appliance
    user_data = [ for i,v in local.fw.template_values: templatefile("${path.module}/appliance.tpl",v) ]
}