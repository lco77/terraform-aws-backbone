locals {
    create    = var.data.vpc.create
    basename  = var.data.vpc.basename
    vpc       = var.data.vpc
    appliance = var.data.appliance
    user_data = [ for i,v in var.data.appliance.template_values: v != {} ? templatefile("${path.module}/user_data.tpl",v) : "" ]
}