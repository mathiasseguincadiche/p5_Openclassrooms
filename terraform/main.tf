# Configuration Terraform principale pour p5_Openclassrooms
terraform {
  required_version = ">= 1.0.0"

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

# Create a simple EC2 instance for the project
resource "aws_instance" "web_server" {
  ami           = var.ami_id
  instance_type = var.instance_type

  tags = {
    Name    = "p5-openclassrooms-web-server"
    Project = "p5_Openclassrooms"
  }
}
