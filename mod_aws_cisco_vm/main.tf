# appliance public interfaces
resource "aws_network_interface" "public" {
  count                             = local.create ? length(local.vpc.public.az) : 0
  subnet_id                         = local.vpc.public_subnet_ids[count.index]
  source_dest_check                 = false
  description                       = "PUBLIC"
  security_groups                   = [ aws_security_group.public[0].id ]
  tags                              = merge(var.tags, {Name = "${var.resource_prefixes.aws_network_interface}-${local.basename}-router-public-${local.vpc.public.az[count.index]}"})
}

# appliance EIPs
resource "aws_eip" "this" {
  count                             = local.create ? length(local.vpc.public.az) : 0
  domain                            = "vpc"
  network_interface                 = aws_network_interface.public[count.index].id
  associate_with_private_ip         = aws_network_interface.public[count.index].private_ip
  tags                              = merge(var.tags, {Name = "${var.resource_prefixes.aws_eip}-${local.basename}-router-public-${local.vpc.public.az[count.index]}"})
}

# appliance private interfaces
resource "aws_network_interface" "private" {
  count                             = local.create ? length(local.vpc.private.az) : 0
  subnet_id                         = local.vpc.private_subnet_ids[count.index]
  source_dest_check                 = false
  description                       = "PRIVATE"
  security_groups                   = [ aws_security_group.private[0].id ]
  tags                              = merge(var.tags, {Name = "${var.resource_prefixes.aws_network_interface}-${local.basename}-router-private-${local.vpc.private.az[count.index]}"})
}

# appliances
resource "aws_instance" "this" {
  count                             = local.create ? length(local.vpc.private.az) : 0
  # Base settings
  ami                               = data.aws_ami.this.id
  instance_type                     = local.appliance.instance_type
  key_name                          = local.appliance.ssh_key
  availability_zone                 = lookup(var.map_code_to_region,local.vpc.private.az[count.index],"")
  ebs_optimized                     = true
  disable_api_termination           = false
  instance_initiated_shutdown_behavior = "stop"
  monitoring                        = false  
  # Bootstrap
  user_data                         = local.user_data[count.index] != "" ? local.user_data[count.index] : null
  # Disk
  root_block_device {
    delete_on_termination           = true
    encrypted                       = true
    kms_key_id                      = data.aws_kms_alias.current_arn.target_key_arn
    tags                            = merge(var.tags, {Name = "${var.resource_prefixes.aws_ebs_volume}-${local.basename}-router-${local.vpc.private.az[count.index]}"})
  }
  # Network interfaces
  network_interface {
    network_interface_id            = aws_network_interface.public[count.index].id
    device_index                    = 0
  }
  network_interface {
    network_interface_id            = aws_network_interface.private[count.index].id
    device_index                    = 1
  }
  # Metadata
  tags                              = merge(var.tags, {Name = "${var.resource_prefixes.aws_instance}-${local.basename}-router-${local.vpc.private.az[count.index]}"})
  lifecycle { ignore_changes        = [ ami, user_data ] }
  # Set dependency on "aws_ec2_transit_gateway_connect_peer.this" so we can generate userdata based on its values
  depends_on = [ aws_ec2_transit_gateway_connect_peer.this ]
}

# TGW connect peer
resource "aws_ec2_transit_gateway_connect_peer" "this" {
  count                             = local.create ? length(local.vpc.private.az) : 0
  peer_address                      = aws_network_interface.private[count.index].private_ip
  bgp_asn                           = local.appliance.bgp_asn
  inside_cidr_blocks                = [local.vpc.private.tunnel_cidr[count.index]]
  transit_gateway_attachment_id     = local.vpc.tgw_connect_id
  tags                              = merge(var.tags, {Name = "${var.resource_prefixes.aws_ec2_transit_gateway_connect_peer}-${local.basename}-router-${local.vpc.private.az[count.index]}"})
}