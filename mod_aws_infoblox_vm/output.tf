output output {
  value = {
    "id":   local.create ? aws_instance.this[*].id  : null
    "eth0": local.create ? flatten(aws_network_interface.eth0[*].private_ips)  : null
    "eth1": local.create ? flatten(aws_network_interface.eth1[*].private_ips)  : null
    "az":   local.create ? local.az : null
  }
}

