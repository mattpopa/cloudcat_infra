output "ns_records" {
  value = aws_route53_zone.cloudcat.name_servers
}
