# Identify hosted zone
 resource "aws_route53_zone" "name" {
  name = var.domain-name
}
 
 
 # Create a record for your domain name
resource "aws_route53_record" "terraform" {
  zone_id = aws_route53_zone.name.zone_id
  name    = "terraform-test"
  type    = "A"
  
  alias {
    name = var.application-load_balancer_dns_name
    zone_id = var.application-load_balancer_zone_id
    evaluate_target_health = true
  }
}


