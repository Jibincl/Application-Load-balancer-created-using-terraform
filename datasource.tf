data "aws_route53_zone" "selected" {
  name         = "sanudas.online"
  private_zone = false
}

output "zone" {
value = data.aws_route53_zone.selected.id
}
