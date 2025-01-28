terraform {
  required_providers {
    awx = {
      source  = "denouche/awx"
    }
  }
}

provider "awx" {
  hostname = "https://ansible-aap-dev.mycompany.com"  # Replace with var.awx_hostname for variable usage
  username = "admin"                      # Replace with var.awx_username for variable usage
  password = "Welcome123"                 # Replace with var.awx_password for variable usage        
}

# Variable for aap development environment configuration
variable "ansible_dev_config" {
  description = "Map of Ansible configuration values for the development environment"
  type        = map(string)
  default = {
    ansible_pat_token = "not-a-real-token"
    ansible_hostname = "ansible-aap-dev.mycompany.com"
    ansible_aws_eu_inventory    = "5"
    rhel_dev_inventory_group_id = "25"
    rhel_dev_workflow_job_timeout_seconds = "1800"
    rhel_dev_wait_before_execution = "1m"
    rhel_dev_workflow_job_template_id = "19"
    rhel_test_inventory_group_id = "27"
    rhel_test_workflow_job_timeout_seconds = "1800"
    rhel_test_wait_before_execution = "1m"
    rhel_test_workflow_job_template_id = "19"
    rhel_prod_inventory_group_id = "21"
    rhel_prod_workflow_job_timeout_seconds = "1800"
    rhel_prod_wait_before_execution = "1m"
    rhel_prod_workflow_job_template_id = "19"
    windows_dev_inventory_group_id = "26"
    windows_dev_workflow_job_timeout_seconds = "1800"
    windows_dev_wait_before_execution = "15m"
    windows_dev_workflow_job_template_id = "23"
    windows_test_inventory_group_id = "28"
    windows_test_workflow_job_timeout_seconds = "1800"
    windows_test_wait_before_execution = "15m"
    windows_test_workflow_job_template_id = "23"
    windows_prod_inventory_group_id = "22"
    windows_prod_workflow_job_timeout_seconds = "1800"
    windows_prod_wait_before_execution = "15m"
    windows_prod_workflow_job_template_id = "23"
  }
}

# Variable for aap production environment configuration
variable "ansible_prod_config" {
  description = "Map of Ansible configuration values for the production environment"
  type        = map(string)
  default = {
    ansible_pat_token = "not-a-real-token"
    ansible_hostname = "ansible-aap-prod.mycompany.com"
    ansible_aws_eu_inventory    = "5"
    rhel_dev_inventory_group_id = "25"
    rhel_dev_workflow_job_timeout_seconds = "1800"
    rhel_dev_wait_before_execution = "1m"
    rhel_dev_workflow_job_template_id = "18"
    rhel_test_inventory_group_id = "27"
    rhel_test_workflow_job_timeout_seconds = "1800"
    rhel_test_wait_before_execution = "1m"
    rhel_test_workflow_job_template_id = "19"
    rhel_prod_inventory_group_id = "21"
    rhel_prod_workflow_job_timeout_seconds = "1800"
    rhel_prod_wait_before_execution = "1m"
    rhel_prod_workflow_job_template_id = "19"
    windows_dev_inventory_group_id = "26"
    windows_dev_workflow_job_timeout_seconds = "1800"
    windows_dev_wait_before_execution = "15m"
    windows_dev_workflow_job_template_id = "23"
    windows_test_inventory_group_id = "28"
    windows_test_workflow_job_timeout_seconds = "1800"
    windows_test_wait_before_execution = "15m"
    windows_test_workflow_job_template_id = "23"
    windows_prod_inventory_group_id = "22"
    windows_prod_workflow_job_timeout_seconds = "1800"
    windows_prod_wait_before_execution = "15m"
    windows_prod_workflow_job_template_id = "23"
  }
}

locals {
  environment = var.tags["environment"]  # Extract environment from tags
  operating_system = var.operating_system  # Extract operating system from variables

  # Determine the OS key based on the operating system
  os_key = (
    can(regex(".*rhel.*|.*linux.*", lower(local.operating_system))) ? "rhel" :
    can(regex(".*suse.*", lower(local.operating_system))) ? "suse" :
    can(regex(".*win.*", lower(local.operating_system))) ? "windows" :
    "unknown"
  )

  # Determine the environment key based on the environment
  env_key = (
    can(regex(".*dev.*|.*development.*", lower(local.environment))) ? "dev" :
    can(regex(".*prod.*|.*production.*", lower(local.environment))) ? "prod" :
    can(regex(".*test.*", lower(local.environment))) ? "test" :
    "unknown"
  )

  # Select the appropriate configuration based on the environment
  ansible_config = local.env_key == "production" ? var.ansible_prod_config : var.ansible_dev_config

  # Map environment and OS to inventory group IDs
  env_os_groups = {
    "dev" = {
      "rhel"    = local.ansible_config["rhel_dev_inventory_group_id"]
      "windows" = local.ansible_config["windows_dev_inventory_group_id"]
    }
    "test" = {
      "rhel"    = local.ansible_config["rhel_test_inventory_group_id"]
      "windows" = local.ansible_config["windows_test_inventory_group_id"]
    }
    "prod" = {
      "rhel"    = local.ansible_config["rhel_prod_inventory_group_id"]
      "windows" = local.ansible_config["windows_prod_inventory_group_id"]
    }
  }

  # Select the inventory group ID based on environment and OS
  selected_group_id = local.env_os_groups[local.env_key][local.os_key]
}

# Fetch the AWX inventory by ID
data "awx_inventory" "selected_inventory" {
  id = local.ansible_config["ansible_aws_eu_inventory"]
}

# Uncomment the following block to use the default workflow job template
# data "awx_workflow_job_template" "default" {
#   id = local.ansible_config["${local.os_key}_${local.env_key}_workflow_job_template_id"]
# }

# Resource to add a host to the AWX inventory
resource "awx_host" "add_host" {
  inventory_id = data.awx_inventory.selected_inventory.id
  group_ids    = [local.selected_group_id]
  name         = upper("${var.hostname}.example.com")
  description  = "EC2 instance in ${local.env_key} environment"
  enabled      = true
  variables    = jsonencode({
    ansible_host = "${aws_instance.ec2_instance.private_ip}",
  })
  depends_on = [ null_resource.wait_for_instance_status ]
}

# Resource to launch an AWX workflow job template
resource "awx_workflow_job_template_launch" "launch_workflow" {
  workflow_job_template_id = local.ansible_config["${local.os_key}_${local.env_key}_workflow_job_template_id"]
  wait_for_completion      = true
  limit                    = upper("${var.hostname}.example.com")
  extra_vars               = jsonencode({
    Access_Target_AD = "aws-123456-admin"
    Hostname         = upper("${var.hostname}.example.com")
    OS               = var.operating_system
    ServerRole       = var.tags["serverrole"]
    Environment      = var.tags["environment"]
  })
  depends_on = [ awx_host.add_host ]
}