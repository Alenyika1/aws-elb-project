module "vpc" {
    source                             = "../child-modules/vpc"
    cidr_block                         = "192.20.0.0/16"
    environment                        = "dev-playground"
    vpc_name                           = "my-vpc"
    state                              = "available" 
}

module "ec2-compute" {
    source                              = "../child-modules/ec2-compute"
    ami                                 = "ami-0ff1c68c6e837b183"
    instance_type                       = "t2.micro" 
    environment                         = "dev-playground"
    key_name                            = "key-pair"
    key_filename                        = "/home/vagrant/.ssh/id_rsa"
    security-block                      = "group-security"
    vpc_id                              = module.vpc.vpc_id
    public_subnet_id-a                  = module.vpc.public_subnet_id-a
    public_subnet_id-b                  = module.vpc.public_subnet_id-b 
    public_subnet_id-c                  = module.vpc.public_subnet_id-c
    alb-sg-id                           = module.elb.alb-sg-id 
    
}





module "route-53" {
  source                                  = "../child-modules/route-53"
  domain-name                             = "zenitugo.com.ng"
  sub-domain                              = "terraform-test"
  environment                             = "dev-playground"
  vpc_id                                  = module.vpc.vpc_id
  application-load_balancer_zone_id       = module.elb.application-load_balancer_zone_id
  application-load_balancer_dns_name      = module.elb.application-load_balancer_dns_name
}


module "elb" {
  source                                   = "../child-modules/elb"
  alb-name                                 = "my-alb"
  load_balancer_type                       = "application"
  public_subnet_id-a                       = module.vpc.public_subnet_id-a
  public_subnet_id-b                       = module.vpc.public_subnet_id-b 
  public_subnet_id-c                       = module.vpc.public_subnet_id-c 
  alb-tg                                   = "my-target-group"
  target_type                              = "instance" 
  vpc_id                                   = module.vpc.vpc_id
  instance-id                              = module.ec2-compute.instance-id 
}

