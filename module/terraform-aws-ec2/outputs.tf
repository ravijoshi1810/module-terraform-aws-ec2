/*
   AWS Linux Module Outputs
*/

output "account_name" {
  description = "AWS Account Alias"
  value       = data.aws_iam_account_alias.account_name.account_alias
}

output "private_ip" {
  value = aws_instance.ec2_instance.private_ip
}

output "public_ip" {
  value = aws_instance.ec2_instance.public_ip
}
#Enable if want to test the cloud-init script
# output "rendered_user_data" {
#   value = templatefile(local.cloud_init_script[local.os_pattern], {
#     user_data_runtime_creds  = var.user_data_runtime_creds
#   })
# }

