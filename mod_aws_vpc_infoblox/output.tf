output "output" {
    value = {
        # Meta data
        basename            = local.basename
        fullname            = "vpc-${local.basename}"
        account             = var.vpc.account
        region              = var.vpc.region
        environment         = var.vpc.environment
        release             = var.vpc.release
        create              = var.vpc.create
        dual_stack          = var.vpc.dual_stack
        log                 = var.vpc.log
        cidr                = var.vpc.cidr
        public              = var.vpc.public
        private             = var.vpc.private
        transit             = var.vpc.transit
        # Resource data
        vpc_id              = var.vpc.create ? aws_vpc.this[0].id : null
        igw_id              = local.create_public_subnets  && var.vpc.public.dia ? aws_internet_gateway.this[0].id : null
        egw_id              = local.create_public_subnets  && var.vpc.public.dia && var.vpc.dual_stack ? aws_egress_only_internet_gateway.this[0].id : null
        ngw_id              = local.create_public_subnets  && local.create_private_subnets && var.vpc.public.dia && var.vpc.private.dia ? aws_nat_gateway.this[0].id : null
        tgw_attachment_id   = var.vpc.create && var.vpc.transit != {} ? aws_ec2_transit_gateway_vpc_attachment.this[0].id : null
        nat_eip_ids         = local.create_public_subnets  && local.create_private_subnets && var.vpc.public.dia && var.vpc.private.dia ? aws_eip.nat[*].id : null
        public_subnet_ids   = local.create_public_subnets  ? aws_subnet.public[*].id : null
        private_subnet_ids  = local.create_private_subnets ? aws_subnet.private[*].id : null
        transit_subnet_ids  = local.create_transit_subnets ? aws_subnet.transit[*].id : null
        public_rtb_ids      = local.create_public_subnets  ? aws_route_table.public[*].id : null
        private_rtb_ids     = local.create_private_subnets ? concat(aws_route_table.private[*].id,aws_route_table.private_with_nat[*].id) : null
        transit_rtb_ids     = local.create_transit_subnets ? aws_route_table.transit[*].id : null
        public_vmdebug_ids  = local.create_public_subnets  && var.vpc.public.vm_debug ? aws_instance.public[*].id : null
        private_vmdebug_ids = local.create_private_subnets && var.vpc.private.vm_debug ? aws_instance.private[*].id : null
        transit_vmdebug_ids = local.create_transit_subnets && var.vpc.transit.vm_debug ? aws_instance.transit[*].id : null
    }
}