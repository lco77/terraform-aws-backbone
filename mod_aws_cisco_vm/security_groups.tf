
# create security group for public interface
resource "aws_security_group" "public" {
    count                             = local.create ? 1 : 0
    name                              = "${local.basename}-router-public"
    description                       = "Security group for Transport Interfaces"
    vpc_id                            = local.vpc.vpc_id
    tags                              = merge(var.tags,{Name = "sg-${local.basename}-router-public"})
}

# create security group for private interface
resource "aws_security_group" "private" {
    count                             = local.create ? 1 : 0
    name                              = "${local.basename}-private"
    description                       = "Security group for Service Interfaces"
    vpc_id                            = local.vpc.vpc_id
    tags                              = merge(var.tags,{Name = "sg-${local.basename}-router-private"})
}


# Inbound security group rules for public interface
resource "aws_security_group_rule" "public_icmp" {
    count             = local.create ? 1 : 0
    type              = "ingress"
    from_port         = -1
    to_port           = -1
    protocol          = "ICMP"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = aws_security_group.public[0].id
    description       = "public ingress: allow ICMP from any source"
} 

resource "aws_security_group_rule" "public_dtls" {
    count             = local.create ? 1 : 0
    type              = "ingress"
    from_port         = 12346
    to_port           = 12426
    protocol          = "UDP"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = aws_security_group.public[0].id
    description       = "public ingress: allow DTLS from any source"
} 

resource "aws_security_group_rule" "public_whitelist" {
    for_each = local.create ? local.appliance.public_whitelist : {}
    type              = "ingress"
    from_port         = 0
    to_port           = 65535
    protocol          = -1
    cidr_blocks       = [each.value]
    security_group_id = aws_security_group.public[0].id
    description       = "public ingress: allow from ${each.key}"
} 


# Outbound security group rules for public interface
resource "aws_security_group_rule" "public_egress" {
    count             = local.create ? 1 : 0
    type              = "egress"
    from_port         = 0
    to_port           = 65535
    protocol          = -1
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = aws_security_group.public[0].id
    description       = "public egress: allow all on CSR Transport interfaces"
}

# Inbound security group rules for private interface
resource "aws_security_group_rule" "private_ingress" {
    count             = local.create ? 1 : 0
    type              = "ingress"
    from_port         = 0
    to_port           = 65535
    protocol          = 47
    cidr_blocks       = [ local.vpc.tgw_cidr ]
    security_group_id = aws_security_group.private[0].id
    description       = "private ingress: allow GRE tunneling from TGW CIDR"
}

# Outbound security group rules for private interface
resource "aws_security_group_rule" "private_egress" {
    count             = local.create ? 1 : 0
    type              = "egress"
    from_port         = 0
    to_port           = 65535
    protocol          = 47
    cidr_blocks       = [ local.vpc.tgw_cidr ]
    security_group_id = aws_security_group.private[0].id
    description       = "private egress: allow GRE tunneling to TGW CIDR"
}