//add locals for tags
locals {
  // locals for EC2 and EBS common tags
  ec2_ebs_common_tags = {
    Name            = "ec2-instance"
    environment     = "Dev"
    applicationname = "Terraform"
    account_id      = "123456789012"
    owner_email     = "rj@example.com"
  }

  ec2_specific_tags = {
    os-version = "RHEL 9.1"
    serverrole = "others"
  }

  // Final EC2 tags 
  ec2_tags = merge(local.ec2_ebs_common_tags, local.ec2_specific_tags)

  // Final EBS tags 
  ebs_tags = local.ec2_ebs_common_tags
}

module "aws_instance_example" {
instance_type           = "t2.micro"
#rest of the Configuration
}
  # Source and Dependencies
  source     = "./module/terraform-aws-ec2" # add private registry path if using terraform private Module registry
  #version    = "1.0.0"               #enable versioning if using terraform private Module registry
  depends_on = []

  # Global or Account Details
  account_id = "123456789012"
  region     = "eu-west-1"

  # Instance Details
  ami_owner               = "123456789012"
  hostname                = "example-instance"
  iam_role                = "AmazonEC2RoleforSSM"
  instance_type           = "t2.micro"
  operating_system        = "RHEL 9"
  user_data_runtime_creds = can(regex("(?i)windows", local.ec2_specific_tags["os-version"])) ? var.akv_local_user_aws_window_vm : var.akv_local_user_aws_linux_vm

  # Network Configuration
  security_groups = ["sg_app"]
  subnet_name     = "PrivateSubnet"
  vpc_name        = "VPC"

  # Volume Configuration
  kms_key_id         = "arn:aws:kms:eu-west-1:123456789012:key/example-key"
  root_vol_size      = 10
  root_vol_type      = "gp2"
  sec_vol_mount_name = ["/app1", "/app2", "/app3"]
  sec_vol_name       = ["xvde", "xvdf", "xvdg"]
  sec_vol_size       = [3, 4, 5]
  sec_vol_type       = ["gp3", "io1", "gp3"]
  sec_iops_value     = [null, 100, null]
  sec_vol_name_decom = [] # use only if you want to decommission the volume
  # Tags
  tags     = local.ec2_tags
  tags_ebs = local.ebs_tags

  # Load Balancer Configuration
  enable_loadbalancer_attachment = false
  
}

# Template Outputs
output "OUTPUT_example_IP" {
  value = module.aws_instance_example.private_ip
}

output "OUTPUT_example_ACCOUNT" {
  value = module.aws_instance_example.account_name
}

