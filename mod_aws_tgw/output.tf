output "output" {
  value = {
    tgw_id   = aws_ec2_transit_gateway.this.id
    tgw_arn  = aws_ec2_transit_gateway.this.arn
    basename = "${var.basename}"
    ram_id   = aws_ram_resource_share.this.id
  }
}
