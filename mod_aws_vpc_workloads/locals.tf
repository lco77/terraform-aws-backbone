locals {
    tags                   = merge(var.tags,var.vpc.tags)
    basename               = "${var.vpc.region}-${var.vpc.environment}-${var.vpc.name}-${var.vpc.release}"
    create_public_subnets  = var.vpc.create && var.vpc.public  != {} && try(length(var.vpc.public.cidr) > 0, false)
    create_private_subnets = var.vpc.create && var.vpc.private != {} && try(length(var.vpc.private.cidr) > 0, false)
    create_transit_subnets = var.vpc.create && var.vpc.transit != {} && try(length(var.vpc.transit.cidr) > 0, false)
    core_vpcs              = { for k,v in var.core: k => v.vpc }

    # Custom or Shared DNS ?
    custom_dns      = try(length(var.vpc.custom_dns.forwarders)>0 && local.create_transit_subnets, false)

    # Local DNS rules
    forwarders             = local.custom_dns ? {for i,v in var.vpc.custom_dns.forwarders: i=>v} : {}
    custom_forward         = local.custom_dns ? try({for i,v in var.vpc.custom_dns.forward_zones: v => {
        name = "${var.resource_prefixes.aws_route53_resolver_rule_forward}-${local.basename}-${replace(v,".","_")}"
        zone = v
    }}): {}
    custom_system         = local.custom_dns ? try({for i,v in var.vpc.custom_dns.system_zones: v => {
        name = "${var.resource_prefixes.aws_route53_resolver_rule_system}-${local.basename}-${replace(v,".","_")}"
        zone = v
    }}): {}

    # Shared DNS rules
    route53_domain         = !local.custom_dns ? try(nonsensitive(var.core[var.vpc.region].route53_domain),null) : null
    route53_resolver       = !local.custom_dns ? try(var.core[var.vpc.region].route53_resolver,null) : null
    route53_zones          = !local.custom_dns ? try(nonsensitive(var.core[var.vpc.region].route53_zones),null) : null
    vpces                  = !local.custom_dns ? try({for i,v in nonsensitive(local.route53_resolver.vpce_inbound_ips): i => v},null) : null

    # Some hardcoding to improve
    rfc1918                = ["10.0.0.0/8","172.16.0.0/12","192.168.0.0/16"]
    vm_type                = "t4g.nano"
    vm_ssh_key             = "nws_systems"

    # Local variables to loop on subnets using for_each
    public_subnets = local.create_public_subnets ? {
        for i,v in try(var.vpc.public.cidr,[]): v => {
            index             = i
            cidr_block        = v
            az                = var.vpc.public.az[i]
            availability_zone = "${lookup(var.map_code_to_region,var.vpc.region,"")}${var.vpc.public.az[i]}"
            name              = "${var.resource_prefixes.aws_subnet}-${local.basename}-${try(var.vpc.public.role[i],"public")}-${var.vpc.public.az[i]}"
            role              = try(var.vpc.public.role[i],"public")
            }
        } : {}

    private_subnets = local.create_private_subnets ? {
        for i,v in try(var.vpc.private.cidr,[]): v => {
            index             = i
            cidr_block        = v
            az                = var.vpc.private.az[i]
            availability_zone = "${lookup(var.map_code_to_region,var.vpc.region,"")}${var.vpc.private.az[i]}"
            name              = "${var.resource_prefixes.aws_subnet}-${local.basename}-${try(var.vpc.private.role[i],"private")}-${var.vpc.private.az[i]}"
            role              = try(var.vpc.private.role[i],"private")
            }
        } : {}

    transit_subnets = local.create_transit_subnets ? {
        for i,v in try(var.vpc.transit.cidr,[]): v => {
            index             = i
            cidr_block        = v
            az                = var.vpc.transit.az[i]
            availability_zone = "${lookup(var.map_code_to_region,var.vpc.region,"")}${var.vpc.transit.az[i]}"
            name              = "${var.resource_prefixes.aws_subnet}-${local.basename}-${try(var.vpc.transit.role[i],"transit")}-${var.vpc.transit.az[i]}"
            role              = try(var.vpc.transit.role[i],"transit")
            }
        } : {}

    # Output
    output = {
        # Config data
        basename             = var.vpc.name
        fullname             = "vpc-${local.basename}"
        account              = var.vpc.account
        region               = var.vpc.region
        environment          = var.vpc.environment
        release              = var.vpc.release
        create               = var.vpc.create
        dual_stack           = var.vpc.dual_stack
        log                  = var.vpc.log
        public               = var.vpc.public
        private              = var.vpc.private
        transit              = var.vpc.transit
        # Resource data
        vpc_id               = var.vpc.create ? aws_vpc.this[0].id : null
        igw_id               = local.create_public_subnets  && var.vpc.public.dia ? aws_internet_gateway.this[0].id : null
        egw_id               = local.create_public_subnets  && var.vpc.public.dia && var.vpc.dual_stack ? aws_egress_only_internet_gateway.this[0].id : null
        ngw_ids              = local.create_public_subnets  && local.create_private_subnets && var.vpc.public.dia && var.vpc.private.dia ? [for k,v in aws_nat_gateway.this: v.id] : null
        tgw_attachment_id    = var.vpc.create && var.vpc.transit != {} ? aws_ec2_transit_gateway_vpc_attachment.this[0].id : null
        nat_eip_ids          = local.create_public_subnets  && local.create_private_subnets && var.vpc.public.dia && var.vpc.private.dia ? [for k,v in aws_eip.nat: v.id] : null
        public_net_ids       = local.create_public_subnets  ?  [for k,v in aws_subnet.public: v.id] : null
        private_net_ids      = local.create_private_subnets ?  [for k,v in aws_subnet.private: v.id] : null
        transit_net_ids      = local.create_transit_subnets ?  [for k,v in aws_subnet.transit: v.id] : null
        public_rtb_ids       = local.create_public_subnets  ?  aws_route_table.public[*].id : null
        private_rtb_ids      = local.create_private_subnets ?  concat(aws_route_table.private[*].id,[for k,v in aws_route_table.private_with_nat: v.id]) : null
        transit_rtb_ids      = local.create_transit_subnets ?  aws_route_table.transit[*].id : null
        public_vmdebug_ids   = local.create_public_subnets  && var.vpc.public.vm_debug ?  [for k,v in aws_instance.public: v.id] : null
        public_vmdebug_ips   = local.create_public_subnets  && var.vpc.public.vm_debug ?  [for k,v in aws_instance.public: v.private_ip] : null
        private_vmdebug_ids  = local.create_private_subnets && var.vpc.private.vm_debug ? [for k,v in aws_instance.private: v.id] : null
        private_vmdebug_ips  = local.create_private_subnets && var.vpc.private.vm_debug ? [for k,v in aws_instance.private: v.private_ip] : null
        transit_vmdebug_ids  = local.create_transit_subnets && var.vpc.transit.vm_debug ? [for k,v in aws_instance.transit: v.id] : null
        transit_vmdebug_ips  = local.create_transit_subnets && var.vpc.transit.vm_debug ? [for k,v in aws_instance.transit: v.private_ip] : null
        outbound_resolver_id = local.custom_dns ? aws_route53_resolver_endpoint.outbound[0].id : null
        outbound_resolver_ips = local.custom_dns ? [ for i,v in aws_route53_resolver_endpoint.outbound[0].ip_address: v.ip] : null
    }
}