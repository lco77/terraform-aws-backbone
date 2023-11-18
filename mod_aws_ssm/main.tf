# Create SSH public keys
resource "aws_key_pair" "this" {
  for_each       = var.variables.ssh_keys
  key_name                = each.key
  public_key              = each.value
}

# Create IPv4 prefix lists
resource "aws_ec2_managed_prefix_list" "ipv4" {
  for_each       = var.variables.ipv4_prefixes
  name           = "${var.variables.map_resource_prefixes.aws_ec2_managed_prefix_list_ipv4}-${each.key}"
  address_family = "IPv4"
  max_entries    = 10
  tags           = var.tags

  dynamic "entry" {
    for_each = each.value

    content {
      cidr        = entry.value
      description = entry.key
    }
  }
}

# Create IPv6 prefix lists
resource "aws_ec2_managed_prefix_list" "ipv6" {
  for_each       = var.variables.ipv6_prefixes
  name           = "${var.variables.map_resource_prefixes.aws_ec2_managed_prefix_list_ipv6}-${each.key}"
  address_family = "IPv6"
  max_entries    = 10
  tags           = var.tags

  dynamic "entry" {
    for_each = each.value

    content {
      cidr        = entry.value
      description = entry.key
    }
  }
}

# Create SSM parameters
resource "aws_ssm_parameter" "this" {
  for_each    = {for k,v in var.variables: k => v if length(regexall("ssh_keys|ipv4_prefixes|ipv6_prefixes", k)) == 0 }
  name        = "${var.path}/${each.key}"
  description = "Configuration item - Do not delete !"
  type        = "String"
  value       = jsonencode(each.value)
  tags        = var.tags
}
