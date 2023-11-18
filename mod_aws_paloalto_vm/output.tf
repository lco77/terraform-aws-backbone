output output {
    value = {
        security_group_id      = local.create ? aws_security_group.this[0].id : null
        eni_public_ids         = local.create ? aws_network_interface.public[*].id : null
        eni_public_ips         = local.create ? aws_network_interface.public[*].private_ip : null
        eni_private_ids        = local.create ? aws_network_interface.private[*].id : null
        eni_private_ips        = local.create ? aws_network_interface.private[*].private_ip : null
        eni_management_ids     = local.create ? aws_network_interface.management[*].id : null
        eni_management_ips     = local.create ? aws_network_interface.management[*].private_ip : null
        eip_ids                = local.create ? aws_eip.this[*].id : null
        eip_ips                = local.create ? aws_eip.this[*].public_ip : null
        instance_ids           = local.create ? aws_instance.this[*].id : null
        gwlb_target_ids        = local.create ? [ for k,v in aws_lb_target_group_attachment.this: v.id ] : null
    }
}