locals {
    vpc      = var.data.vpc[var.region]
    tgw      = lookup(var.data.tgw,var.region,"")
    rtb      = var.data.rtb[var.region]
    basename = "${local.vpc.region}-${local.vpc.environment}-${local.vpc.name}-${local.vpc.release}"
    rfc1918  = ["10.0.0.0/8","172.16.0.0/12","192.168.0.0/16"]
}
