output output {
  value = { for i,v in aws_route53_zone.this: v.name => {id = v.zone_id, arn = v.arn} }
}

