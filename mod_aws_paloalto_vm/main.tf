# IAM role
resource "aws_iam_role" "this" {
  count                             = local.create ? 1 : 0
  name                              = "${var.resource_prefixes.aws_iam_role}-firewall-${random_id.this.hex}"
  assume_role_policy                = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# IAM policy
resource "aws_iam_policy" "this" {
  count                             = local.create ? 1 : 0
  name                              = "${var.resource_prefixes.aws_iam_policy}-firewall-${random_id.this.hex}"
  path                              = "/"
  description                       = "IAM Policy for VM-Series Firewall"
  policy                            = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
        {
            "Action": "s3:ListBucket",
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": "s3:GetObject",
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "ec2:AttachNetworkInterface",
                "ec2:DetachNetworkInterface",
                "ec2:DescribeInstances",
                "ec2:DescribeNetworkInterfaces"
            ],
            "Resource": [
                "*"
            ],
            "Effect": "Allow"
        },
        {
            "Action": [
                "cloudwatch:PutMetricData"
            ],
            "Resource": [
                "*"
            ],
            "Effect": "Allow"
        }
  ]
}
EOF
}

# Attach role to policy
resource "aws_iam_role_policy_attachment" "this" {
  count                             = local.create ? 1 : 0
  role                              = aws_iam_role.this[0].name
  policy_arn                        = aws_iam_policy.this[0].arn
}

# Instance profile with role
resource "aws_iam_instance_profile" "this" {
  count                             = local.create ? 1 : 0
  name                              = "${var.resource_prefixes.aws_iam_instance_profile}-firewall-${random_id.this.hex}"
  role                              = aws_iam_role.this[0].name
}

# Firewall security group
resource "aws_security_group" "this" {
  count                             = local.create ? 1 : 0
  vpc_id                            = local.vpc.vpc_id
  name                              = "${var.resource_prefixes.aws_security_group}-${local.basename}-firewall"
  ingress {
    from_port                       = 0
    to_port                         = 0
    protocol                        = "-1"
    cidr_blocks                     = ["0.0.0.0/0"]
    ipv6_cidr_blocks                = ["::/0"]
  }
  egress {
    from_port                       = 0
    to_port                         = 0
    protocol                        = "-1"
    cidr_blocks                     = ["0.0.0.0/0"]
    ipv6_cidr_blocks                = ["::/0"]
  }
  tags                              = merge(var.tags, {Name = "${var.resource_prefixes.aws_security_group}-${local.basename}-firewall"})
}

# Firewall public interfaces
resource "aws_network_interface" "public" {
  count                             = local.create ? length(local.vpc.public.cidr) : 0
  subnet_id                         = local.vpc.public_subnet_ids[count.index]
  source_dest_check                 = false
  description                       = "PUBLIC"
  security_groups                   = [ aws_security_group.this[0].id ]
  tags                              = merge(var.tags, {Name = "${var.resource_prefixes.aws_network_interface}-${local.basename}-firewall-public-${local.vpc.public.az[count.index]}"})
}

# Firewall EIPs
resource "aws_eip" "this" {
  count                             = local.create ? length(local.vpc.public.cidr) : 0
  domain                            = "vpc"
  network_interface                 = aws_network_interface.public[count.index].id
  associate_with_private_ip         = aws_network_interface.public[count.index].private_ip
  tags                              = merge(var.tags, {Name = "${var.resource_prefixes.aws_eip}-${local.basename}-firewall-public-${local.vpc.public.az[count.index]}"})
}

# Firewall private interfaces
resource "aws_network_interface" "private" {
  count                             = local.create ? length(local.vpc.private.cidr) : 0
  subnet_id                         = local.vpc.private_subnet_ids[count.index]
  source_dest_check                 = false
  description                       = "PRIVATE"
  security_groups                   = [ aws_security_group.this[0].id ]
  tags                              = merge(var.tags, {Name = "${var.resource_prefixes.aws_network_interface}-${local.basename}-firewall-private-${local.vpc.private.az[count.index]}"})
}

# Firewall management interfaces
resource "aws_network_interface" "management" {
  count                             = local.create ? length(local.vpc.management.cidr) : 0
  subnet_id                         = local.vpc.management_subnet_ids[count.index]
  source_dest_check                 = true
  description                       = "MANAGEMENT"
  security_groups                   = [ aws_security_group.this[0].id ]
  tags                              = merge(var.tags, {Name = "${var.resource_prefixes.aws_network_interface}-${local.basename}-firewall-management-${local.vpc.management.az[count.index]}"})
}

# Firewalls
resource "aws_instance" "this" {
  count                             = local.create ? length(local.vpc.private.cidr) : 0
  # Base settings
  ami                               = data.aws_ami.this.id
  instance_type                     = local.fw.instance_type
  iam_instance_profile              = aws_iam_instance_profile.this[0].id
  key_name                          = local.fw.ssh_key
  availability_zone                 = lookup(var.map_code_to_region,local.vpc.private.az[count.index],"")
  ebs_optimized                     = true
  disable_api_termination           = false
  instance_initiated_shutdown_behavior = "stop"
  monitoring                        = false  
  # Bootstrap
  user_data                         = local.user_data[count.index]
  # Disk
  root_block_device {
    delete_on_termination           = true
    encrypted                       = true
    kms_key_id                      = data.aws_kms_alias.current_arn.target_key_arn
    tags                            = merge(var.tags, {Name = "${var.resource_prefixes.aws_ebs_volume}-${local.basename}-firewall-${local.vpc.private.az[count.index]}"})
  }
  # Network interfaces
  network_interface {
    network_interface_id            = aws_network_interface.management[count.index].id
    device_index                    = 0
  }
  network_interface {
    network_interface_id            = aws_network_interface.public[count.index].id
    device_index                    = 1
  }
  network_interface {
    network_interface_id            = aws_network_interface.private[count.index].id
    device_index                    = 2
  }

  # Metadata
  tags                              = merge(var.tags, {Name = "${var.resource_prefixes.aws_instance}-${local.basename}-firewall-${local.vpc.private.az[count.index]}"})
  lifecycle { ignore_changes        = [ ami, user_data ] }
}

# GWLB targets
resource "aws_lb_target_group_attachment" "this" {
  for_each                          = local.create ? { for i,v in local.vpc.private.gwlb_enabled: i => v if v } : { }
  target_group_arn                  = local.vpc.gwlb_tg_arn
  target_id                         = aws_network_interface.private[each.key].private_ip
}