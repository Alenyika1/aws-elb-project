resource "aws_instance" "compute" {
  count = 3
  ami           = var.ami
  instance_type = var.instance_type
  key_name = aws_key_pair.key-pair.id
  subnet_id = [var.public_subnet_id-a, var.public_subnet_id-b, var.public_subnet_id-c][count.index]
  vpc_security_group_ids = [aws_security_group.sg-group.id]


  user_data = file("${path.module}/bash.sh")

  tags = {
    Name = "${var.environment}"
  }

  
}

# Create Key pair
resource "aws_key_pair" "key-pair" {
    key_name = var.key_name
    public_key = tls_private_key.ssh_key.public_key_openssh
}

# Create a Private key
resource "tls_private_key" "key_pair" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Put the private key in a local file
resource "local_file" "testkey_private" {
  content = tls_private_key.ssh_key.private_key_pem
  filename = var.key_filename
}



# Create a security group
resource "aws_security_group" "elb-sg" {
  name = var.security-block
  vpc_id = var.vpc_id

  ingress{
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

   ingress{
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    security_groups = [var.alb-sg-id]
   } 

   egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "security_grp"
  }
}


# Create a resource block to export the public IPs to a host-inventory file
locals {
  public-ip = aws_instance.compute.*.public_ip
}
resource "local_file" "output_file" {
  content  = join("\n", local.public-ip)
  filename = "${path.module}/local_directory/host-inventory.ini"
}


# Create a resource block to export public and private keys that will be used in the linux terminal and ansible controller to provision the three ec2s
resource "local_file" "key" {
  content =   tls_private_key.ssh_key.private_key_pem
  filename = "${path.module}/local_directory/key-pair.pem" 
}

resource "local_file" "key-pub" {
  content =   tls_private_key.ssh_key.public_key_openssh
  filename = "${path.module}/local_directory/key-pair.pub" 
}



# Create an ansible controller
resource "aws_instance" "controller" {
  ami = var.ami
  instance_type = var.instance_type
  key_name = aws_key_pair.key-pair.id
  subnet_id = var.public_subnet_id-a
  vpc_security_group_ids = [aws_security_group.controller-sg.id]

  user_data = base64encode(file("${path.module}/ansible.sh"))
  tags = {
    name = "controller"
  }
}

# Create a security group for the controller
resource "aws_security_group" "controller-sg" {
  name = "controller-sg"
  vpc_id = var.vpc_id

  ingress { 
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }


  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}