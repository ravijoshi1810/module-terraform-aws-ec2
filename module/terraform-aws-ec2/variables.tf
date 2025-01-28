// Instance Variables
variable "account_id" {
  type        = string
  description = "AWS Account ID to provision VM"
  default     = ""
}

variable "ami_owner" {
  type        = string
  description = "ID of AMI owner to use for the instance"
  default     = ""
}

variable "encryption" {
  type        = string
  description = "If true, the EC2 instance Disk will be encrypted"
  default     = "true"
}

variable "final_snapshot" {
  type        = string
  description = "If true, the EC2 instance will take a final snapshot"
  default     = "false"
}

variable "force_detach" {
  type        = string
  description = "If true, the EC2 instance will force detach the volume"
  default     = "true"
}

variable "hostname" {
  type        = string
  description = "Hostname of the VM"
  default     = ""
}

variable "iam_role" {
  type        = string
  description = "IAM Role to assign to the VM"
  default     = "AmazonEC2RoleforSSM"
}

variable "instance_type" {
  type        = string
  description = "Type of instance to start"
  default     = ""
}

variable "key_name_os" {
  type        = string
  description = "Key Name to use for the instance"
  default     = ""
}

variable "kms_key_id" {
  type        = string
  description = "KMS Key to encrypt the instance disk"
  default     = ""
}

variable "operating_system" {
  type        = string
  description = "Operating System of VM"
  default     = ""
}

variable "ppm_id" {
  type        = number
  description = "Application PPM ID"
  default     = null
}

variable "region" {
  type        = string
  description = "AWS Region to provision VM"
  default     = ""
}

variable "root_vol_deletion" {
  type        = string
  description = "If true, the EC2 instance Root Volume will delete on termination"
  default     = "true"
}

variable "root_vol_size" {
  type        = string
  description = "Root Volume Size of Instance"
  default     = ""
}

variable "root_vol_type" {
  type        = string
  description = "Root Volume Type of Instance"
  default     = "gp2"
}

variable "security_groups" {
  type        = list(string)
  description = "list of security groups to attach to the instance"
  default     = []
}

variable "subnet_name" {
  type        = string
  description = "Subnet Name to provision VM"
  default     = ""
}

// Secondary Volume Variables

variable "sec_vol_mount_name" {
  description = "List of secondary volume mount names"
  type        = list(string)
  default     = []
}
variable "sec_vol_name" {
  description = "List of secondary volume names"
  type        = list(string)
  default     = []
}

variable "sec_vol_size" {
  description = "List of secondary volume sizes"
  type        = list(number)
  default     = []
}

variable "sec_vol_type" {
  description = "List of secondary volume types"
  type        = list(string)
  default     = []
}

variable "sec_iops_value" {
  description = "List of IOPS values for IOPS volumes"
  type        = list(number)
  default     = []
}

variable "sec_vol_name_decom" {
  description = "List of secondary volume names to decommission"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "A mapping of tags to assign to all resources"
  type        = map(string)
  default     = {}
}

variable "tags_ebs" {
  description = "A mapping of tags to assign to all resources"
  type        = map(string)
  default     = {}
}

variable "user_data_runtime_creds" {
  type        = string
  description = "User Data Runtime Credentials"
  default     = ""
}


variable "vpc_name" {
  type        = string
  description = "VPC Name to provision VM"
  default     = ""
}

// load balancer variables

variable "enable_loadbalancer_attachment" {
  type        = bool
  description = "If true, the EC2 instance will be attached to the load balancer"
  default     = false
}

variable "loadbalancer_target_group_name" {
  type        = string
  description = "Name of the target group to attach the EC2 instance"
  default     = null
}

variable "loadbalancer_target_group_port" {
  type        = number
  description = "Port of the target group to attach the EC2 instance"
  default     = null
}
