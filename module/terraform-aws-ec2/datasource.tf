// Local Variables
locals {
  os_pattern = regex("(?i)rhel|windows|suse", lower(var.operating_system))
  architecture = can(regex(".*arm.*", lower(var.operating_system))) ? "arm64" : "x86_64"
  cloud_init_script = {
    "rhel"    = "${path.module}/cloud-init-scripts/rhel-cloud-init.sh"
    "windows" = "${path.module}/cloud-init-scripts/win-cloud-init.tmpl"
    "suse"    = "${path.module}/cloud-init-scripts/suse-cloud-init.sh"
  }
  key_name_os = contains(["windows"], local.os_pattern) ? "windows" : "linux"
}

// Fetch Recent Updated AMI
data "aws_ami" "ami" {
  most_recent = true
  owners      = [var.ami_owner]
  filter {
    name   = "name"
    values = ["*${var.operating_system}*"]
  }
  filter {
    name   = "architecture"
    values = [local.architecture]
  }
}

// AWS Account Alias
data "aws_iam_account_alias" "account_name" {}

// AWS KMS ARN for EBS
data "aws_kms_key" "by_key_arn" {
  key_id = var.kms_key_id
}

// Hosted Zone of Route53
data "aws_route53_zone" "selected" {
  name         = "${var.account_id}.${var.region}.example.com"
  private_zone = true
}

// Fetch Security Group IDs through Security Group Names
data "aws_security_group" "sg" {
  for_each = toset(var.security_groups)
  name     = each.value
}

// Fetch Subnet ID using VPC and Subnet Name
data "aws_subnet" "subnet" {
  vpc_id = data.aws_vpc.vpc.id

  filter {
    name   = "tag:Name"
    values = [var.subnet_name]
  }
}

// Datasource block used to fetch VPC ID
data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

// AWS ALB Target Group
data "aws_lb_target_group" "tg" {
  count  = var.enable_loadbalancer_attachment == true && var.tags["serverrole"] == "app" ? 1 : 0
  name   = var.loadbalancer_target_group_name
}