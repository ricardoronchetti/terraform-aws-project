terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "local" {}

  #Switch to Remote S3 Backend
  # backend "s3" {
  #   bucket         = "ricardoronchetti-terraform-project-state-bucket"
  #   key            = "terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-lock"
  #   encrypt        = true
  # }
}

# Create S3 Bucket and DynamoDB Table
# resource "aws_s3_bucket" "terraform_state" {
#   bucket = "ricardoronchetti-terraform-project-state-bucket"
#   force_destroy = true

#   tags = {
#     Name        = "Terraform State Bucket"
#     Environment = "dev"
#   }
# }

# resource "aws_s3_bucket_versioning" "enabled" {
#   bucket = aws_s3_bucket.terraform_state.id
#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# resource "aws_dynamodb_table" "terraform_locks" {
#   name           = "terraform-lock"
#   billing_mode   = "PAY_PER_REQUEST"
#   hash_key       = "LockID"

#   attribute {
#     name = "LockID"
#     type = "S"
#   }

#   tags = {
#     Name        = "Terraform Lock Table"
#     Environment = "dev"
#   }
# }

# Fetch latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-amd64-server-*"]
  }
  owners = ["099720109477"] # Canonical (Ubuntu) Owner ID
}

# Creating VPC
resource "aws_vpc" "dev_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "dev-vpc"
  }
}

# Creating Internet Gateway
resource "aws_internet_gateway" "dev_gw" {
  vpc_id = aws_vpc.dev_vpc.id
  tags = {
    Name = "dev-gw"
  }
}

# Creating Route Table
resource "aws_route_table" "dev_route_table" {
  vpc_id = aws_vpc.dev_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev_gw.id
  }

  tags = {
    Name = "dev-route-table"
  }
}

# Creating Subnet
resource "aws_subnet" "subnet_1" {
  vpc_id            = aws_vpc.dev_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "dev-subnet"
  }
}

# Subnet to Route Table Association
resource "aws_route_table_association" "dev_assoc" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.dev_route_table.id
}

# Security Group
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow Web inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.dev_vpc.id

  tags = {
    Name = "allow_web"
  }
}

# Allow HTTP and HTTPS from anywhere
resource "aws_security_group_rule" "allow_web_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_web.id
}

resource "aws_security_group_rule" "allow_web_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_web.id
}

# Restrict SSH to a specific IP (change YOUR_IP)
resource "aws_security_group_rule" "allow_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["192.168.1.10/32"]
  security_group_id = aws_security_group.allow_web.id
}

# Allow all outbound traffic
resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_web.id
}

# Creating Ubuntu server and Installing Apache2
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  availability_zone      = "us-east-1a"
  key_name               = "terraform-project-key-pair"
  subnet_id              = aws_subnet.subnet_1.id
  security_groups        = [aws_security_group.allow_web.id]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install -y apache2 git
    cd /tmp
    git clone https://github.com/ricardoronchetti/bluespacerangers.git
    sudo rm -rf /var/www/html/*
    sudo cp -r bluespacerangers/* /var/www/html/
    sudo chown -R www-data:www-data /var/www/html
    sudo chmod -R 755 /var/www/html
    sudo systemctl restart apache2
    EOF

  tags = {
    Name = "web-server-instance"
    Environment = "Development"
    Project     = "Terraform Apache HTTP Server"
  }
}

output "website_url" {
  description = "Access your deployed website here"
  value       = "http://${aws_instance.web_server.public_ip}"
}