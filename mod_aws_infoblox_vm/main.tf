# IAM role
resource "aws_iam_role" "this" {
  count                             = local.create ? 1 : 0
  name                              = "${var.resource_prefixes.aws_iam_role}-grid-member-${random_id.this.hex}"
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
  name                              = "${var.resource_prefixes.aws_iam_policy}-grid-member-${random_id.this.hex}"
  path                              = "/"
  description                       = "IAM Policy for Infoblox Grid members"
  policy                            = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
        {
            "Action": [
                "ec2:AttachNetworkInterface",
                "ec2:DetachNetworkInterface",
                "ec2:DescribeVpcs",
                "ec2:DescribeSubnets",
                "ec2:DescribeRouteTables",
                "ec2:DescribeAddresses",
                "ec2:DescribeInstances",
                "ec2:DescribeNetworkInterfaces"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": "iam:GetUser",
            "Resource": "arn:aws:iam::*:user/*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "cloudwatch:PutMetricData"
            ],
            "Resource": "*",
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
  name                              = "${var.resource_prefixes.aws_iam_instance_profile}-grid-member-${random_id.this.hex}"
  role                              = aws_iam_role.this[0].name
}

# Eth0
resource "aws_network_interface" "eth0" {
  count                   = local.create ? length(local.private_subnet_ids) : 0
  subnet_id               = local.private_subnet_ids[count.index]
  private_ips             = [cidrhost(data.aws_subnet.private_subnets[count.index].cidr_block, 4)]
  security_groups         = [aws_security_group.this[0].id]
  description             = "MGMT"
  tags                    = merge(local.tags,{Name = "${var.resource_prefixes.aws_network_interface}-${local.basename}-grid-member-eth0-${local.az[count.index]}"})
}

# Eth1
resource "aws_network_interface" "eth1" {
  count                   = local.create ? length(local.private_subnet_ids) : 0
  subnet_id               = local.private_subnet_ids[count.index]
  private_ips             = [cidrhost(data.aws_subnet.private_subnets[count.index].cidr_block, 5)]
  security_groups         = [aws_security_group.this[0].id]
  description             = "LAN1"
  tags                    = merge(local.tags,{Name = "${var.resource_prefixes.aws_network_interface}-${local.basename}-grid-member-eth1-${local.az[count.index]}"})
}

resource "aws_instance" "this" {
  count                   = local.create ? length(local.private_subnet_ids) : 0
  instance_type           = local.instance_type
  iam_instance_profile    = aws_iam_instance_profile.this[0].id
  ami                     = data.aws_ami.this.id
  key_name                = local.ssh_key
  user_data               = local.user_data[count.index]
  ebs_optimized           = true
  # Disk
  root_block_device {
    volume_size           = 250
    volume_type           = "gp2"
    delete_on_termination = true
    encrypted             = true
    tags                  = merge(var.tags, {Name = "${var.resource_prefixes.aws_ebs_volume}-${local.basename}-grid-member-${local.az[count.index]}"})
  }
  # Eth0
  network_interface {
    network_interface_id = aws_network_interface.eth0[count.index].id
    device_index         = 0
  }
  # Eth1
  network_interface {
    network_interface_id = aws_network_interface.eth1[count.index].id
    device_index         = 1
  }
  # Metadata
  tags                              = merge(local.tags,{ Name = "${var.resource_prefixes.aws_instance}-${local.basename}-grid-member-${local.az[count.index]}" })
  lifecycle { ignore_changes        = [ami,user_data] }
}

