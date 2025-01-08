output "cloudcat_ns_records" {
  value = aws_route53_zone.cloudcat.name_servers
}

output "host1_ns_records" {
  value = aws_route53_zone.host1.name_servers
}

output "host2_ns_records" {
  value = aws_route53_zone.host2.name_servers
}