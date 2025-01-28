/*
   Backend configuration for CLI Driven Workspace
*/
# enable the remote backend configuration if you are using Terraform Cloud or Terraform Enterprise
// Remote Backend Configuration
terraform {
  # backend "remote" {
  #   organization = "YourOrganization"
  #   hostname     = "your-terraform-hostname.com"
  #   workspaces {
  #     name = "your_workspace_name"
  #    }
  # }

  // Provider versions
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 3.68.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.27.0"
    }
    awx = {
      source  = "denouche/awx"
      version = "0.29.1"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
  assume_role {
    role_arn     = "arn:aws:iam::123456789012:role/Terraform-AutomationExecutionRole"
    session_name = "Automation_Assume_Role"
  }
}

provider "awx" {
  alias    = "awx"
  hostname = "https://your-ansibletower-hostname.com"
  username = var.awx_username
  password = var.awx_password
}