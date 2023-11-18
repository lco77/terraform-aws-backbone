output output {
    value = merge(local.vpc,{
        # Basics
        basename           = local.basename
        vpc_id             = local.vpc.create ? aws_vpc.this[0].id : null
        tgw_id             = local.vpc.create ? local.tgw.tgw_id : null
        tgw_cidr           = local.vpc.create ? local.tgw.cidr : null
        vpc_attachment_id  = local.vpc.create ? aws_ec2_transit_gateway_vpc_attachment.this[0].id : null
        igw_id             = local.vpc.create ? aws_internet_gateway.this[0].id : null
        egw_id             = local.vpc.create ? aws_egress_only_internet_gateway.this[0].id : null
        # Subnets
        public_subnet_ids  = local.vpc.create ? aws_subnet.public[*].id : null
        private_subnet_ids = local.vpc.create ? aws_subnet.private[*].id : null
        transit_subnet_ids = local.vpc.create ? aws_subnet.transit[*].id : null
        public_rtb_id      = local.vpc.create ? aws_route_table.public[0].id : null
        private_rtb_id     = local.vpc.create ? aws_route_table.private[0].id : null
        transit_rtb_ids    = local.vpc.create ? [aws_route_table.transit[*].id] : null
        # TGW Connect
        tgw_connect_id     = local.vpc.create ? aws_ec2_transit_gateway_connect.this[0].id : null
    })
}