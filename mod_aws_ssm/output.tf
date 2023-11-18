output output {
  value = {
    ipv4_prefixes = local.ipv4_prefix_list_ids
    ipv6_prefixes = local.ipv6_prefix_list_ids
    ssh_keys      = local.ssh_keys_ids
  }
}