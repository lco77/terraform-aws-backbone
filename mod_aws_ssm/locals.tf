locals {
  ipv4_prefix_list_ids = {for k,v in aws_ec2_managed_prefix_list.ipv4: k => v.id}
  ipv6_prefix_list_ids = {for k,v in aws_ec2_managed_prefix_list.ipv6: k => v.id}
  ssh_keys_ids         = {for k,v in aws_key_pair.this: k => v.key_pair_id}
}