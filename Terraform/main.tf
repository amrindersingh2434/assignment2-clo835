terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


provider "aws" {
  region = var.aws_region
}


data "aws_iam_instance_profile" "labrole" {
  name = "LabInstanceProfile"
}


resource "aws_ecr_repository" "app" {
  name                 = "clo835-app"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}


resource "aws_ecr_repository" "mysql" {
  name                 = "clo835-mysql"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}




resource "aws_security_group" "app_sg" {
  name        = "clo835-app-sg"
  description = "Allow SSH and App traffic"


  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  
  ingress {
    from_port   = 30000
    to_port     = 30000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.medium"
  vpc_security_group_ids = [aws_security_group.app_sg.id]


  iam_instance_profile = data.aws_iam_instance_profile.labrole.name


   user_data = <<-EOF
    #!/bin/bash
    set -e
    
    # Update system
    yum update -y
    
    # Install required packages
    yum install -y docker git unzip
    
    # Start and enable Docker
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ec2-user
    
    # Install kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    mv kubectl /usr/local/bin/
    
    # Install kind
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
    chmod +x kind
    mv kind /usr/local/bin/
    
    # Install AWS CLI v2
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
    unzip awscliv2.zip
    ./aws/install
    
    # Verify installations
    docker --version
    kubectl version --client
    kind --version
    aws --version
    
    # Create Kubernetes cluster
    sudo -u ec2-user kind create cluster --name clo835
  
  EOF


  tags = {
    Name = "clo-app"
  }
}

resource "aws_key_pair" "k8s" {
  key_name   = "pubkey"
  public_key = file("/home/ec2-user/environment/pubkey.pub")
}