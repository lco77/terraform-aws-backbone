output output {
  value = {
      name = aws_route53_zone.domain.name
      id   = aws_route53_zone.domain.zone_id
      arn  = aws_route53_zone.domain.arn
  }
}

