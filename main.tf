############################################
# Terraform configuration
############################################

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}


############################################
# AWS Provider
############################################

provider "aws" {
  region = "us-east-1"
}


############################################
# Ubuntu AMI
############################################

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name = "name"
    values = [
      "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
    ]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}


############################################
# EC2 Instance
############################################

resource "aws_instance" "chatbot_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  tags = {
    Name        = "ChatbotServer"
    Project     = "Chatbot"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}


############################################
# S3 bucket for chatbot logs
############################################

resource "aws_s3_bucket" "chatbot_logs" {
  bucket_prefix = "chatbot-logs-"

  tags = {
    Name        = "ChatbotLogs"
    Project     = "Chatbot"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}


############################################
# S3 encryption
############################################

resource "aws_s3_bucket_server_side_encryption_configuration" "chatbot_logs" {
  bucket = aws_s3_bucket.chatbot_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


############################################
# Block public access to S3
############################################

resource "aws_s3_bucket_public_access_block" "chatbot_logs" {
  bucket = aws_s3_bucket.chatbot_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


############################################
# Outputs
############################################

output "ec2_instance_id" {
  description = "ID of the chatbot EC2 instance"
  value       = aws_instance.chatbot_server.id
}

output "ec2_public_ip" {
  description = "Public IP of the chatbot EC2 instance"
  value       = aws_instance.chatbot_server.public_ip
}

output "ubuntu_ami_id" {
  description = "Ubuntu AMI selected by Terraform"
  value       = data.aws_ami.ubuntu.id
}

output "chatbot_logs_bucket" {
  description = "S3 bucket used for chatbot logs"
  value       = aws_s3_bucket.chatbot_logs.bucket
}
