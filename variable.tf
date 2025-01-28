/*
   Module Template Variables
*/

# var to store the local user credential for the VM
# can be fetched from Azure Key Vault or any other secret management tool
# can be set to terraform Enterprise or Cloud workspace secret
# can be set to local environment variable
variable "akv_local_user_aws_linux_vm" {
  type        = string
  description = "Local User Credential"
  #default     = "NOT_IN_USE""
}

variable "akv_local_user_aws_window_vm" {
  type        = string
  description = "Local User Credential"
  default     = "NOT_IN_USE"
}

