output output {
    value = merge(local.vpc,{
        # Basics
        basename           = local.basename
        vpc_id             = local.vpc.create ? aws_vpc.this[0].id : null
        tgw_id             = local.vpc.create ? local.tgw.tgw_id : null
        vpc_attachment_id  = local.vpc.create ? aws_ec2_transit_gateway_vpc_attachment.this[0].id : null
        igw_id             = local.vpc.create ? aws_internet_gateway.this[0].id : null
        egw_id             = local.vpc.create ? aws_egress_only_internet_gateway.this[0].id : null
        ngw_ids            = local.vpc.create && local.vpc.management.dia ? aws_nat_gateway.this[*].id : null
        # Subnets
        public_subnet_ids  = local.vpc.create ? aws_subnet.public[*].id : null
        private_subnet_ids = local.vpc.create ? aws_subnet.private[*].id : null
        management_subnet_ids = local.vpc.create ? aws_subnet.management[*].id : null
        transit_subnet_ids = local.vpc.create ? aws_subnet.transit[*].id : null
        public_rtb_id      = local.vpc.create ? aws_route_table.public[0].id : null
        private_rtb_id     = local.vpc.create ? aws_route_table.private[0].id : null
        management_rtb_ids = local.vpc.create ? aws_route_table.management[*].id : null
        transit_rtb_ids    = local.vpc.create ? aws_route_table.transit[*].id : null
        # GWLB
        gwlb_arn           = local.vpc.create ? aws_lb.this[0].arn : null
        gwlb_tg_arn        = local.vpc.create ? aws_lb_target_group.this[0].arn : null
        gwlb_vpce_svc_id   = local.vpc.create ? aws_vpc_endpoint_service.this[0].id : null
        gwlb_vpce_svc_arn  = local.vpc.create ? aws_vpc_endpoint_service.this[0].arn : null
        gwlb_vpce_ids      = local.vpc.create ? aws_vpc_endpoint.this[*].id : null
        gwlb_vpce_arns     = local.vpc.create ? aws_vpc_endpoint.this[*].arn : null
        gwlb_listener_arn  = local.vpc.create ? aws_lb_listener.this[0].arn : null
    })
}