locals {
  # Create a map for EBS volumes
  ebs_volumes = zipmap(var.sec_vol_name, [
    for i in range(length(var.sec_vol_name)) : {
      type = var.sec_vol_type[i]
      size = var.sec_vol_size[i]
      iops = var.sec_vol_type[i] == "io1" || var.sec_vol_type[i] == "io2" ? var.sec_iops_value[i] : null
    }
  ])

  # Filter out the volumes to be removed
  filtered_volumes = { for k, v in local.ebs_volumes : k => v if !contains(var.sec_vol_name_decom, k) }

  # Filter tags excluding specific tags
  filtered_tags = { for k, v in var.tags : k => v if k != "account-name" && k != "owner_email" }
}

resource "aws_instance" "ec2_instance" {
  ami                   = data.aws_ami.ami.id
  instance_type         = var.instance_type
  subnet_id             = data.aws_subnet.subnet.id
  vpc_security_group_ids = [for sg in data.aws_security_group.sg : sg.id]
  user_data             = templatefile(local.cloud_init_script[local.os_pattern], {
    user_data_runtime_creds  = var.user_data_runtime_creds
  })
  iam_instance_profile  = var.iam_role
  key_name              = "${data.aws_iam_account_alias.account_name.account_alias}-${local.key_name_os}"
  tags                  = merge(local.filtered_tags, { owner_email = var.owner_email })

  root_block_device {
    volume_size           = var.root_vol_size
    volume_type           = var.root_vol_type
    delete_on_termination = var.root_vol_deletion
    kms_key_id            = data.aws_kms_key.by_key_arn.key_id
    encrypted             = var.encryption
    tags = merge(
      local.filtered_tags,
      {
        Name     = "${local.filtered_tags["Name"]}-root-vol",
        ebs_type = var.root_vol_type
      }
    )
  }

  lifecycle {
    ignore_changes = [
      ami,
      user_data,
      tags.account-name,
      tags.owner_email
    ]
  }
}

resource "aws_ebs_volume" "ebs_volume" {
  for_each          = local.filtered_volumes
  availability_zone = data.aws_subnet.subnet.availability_zone
  final_snapshot    = var.final_snapshot
  size              = each.value.size
  type              = each.value.type
  kms_key_id        = var.kms_key_id
  encrypted         = var.encryption
  depends_on        = [aws_instance.ec2_instance]

  iops = each.value.iops != null ? each.value.iops : null

  tags = merge(
    local.filtered_tags,
    {
      Name     = "${local.filtered_tags["Name"]}-data-vol-${each.key}",
      ebs_type = each.value.type
    }
  )

  lifecycle {
    ignore_changes = [
      tags.account-name,
      tags.owner_email
    ]
  }
}

resource "aws_volume_attachment" "volume_attachment" {
  for_each     = aws_instance.ec2_instance != {} ? aws_ebs_volume.ebs_volume : {}
  device_name  = "/dev/${each.key}"
  force_detach = var.force_detach
  volume_id    = each.value.id
  instance_id  = aws_instance.ec2_instance[each.key].id
  depends_on   = [aws_ebs_volume.ebs_volume]
}

resource "aws_route53_record" "record" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${var.hostname}.${data.aws_route53_zone.selected.name}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.ec2_instance[0].private_ip]
  depends_on = [aws_instance.ec2_instance]
}

resource "aws_lb_target_group_attachment" "attach_instance" {
  count            = var.enable_loadbalancer_attachment == true && var.tags["serverrole"] == "app" ? 1 : 0
  target_group_arn = data.aws_lb_target_group.tg[0].arn
  target_id        = aws_instance.ec2_instance[0].id
  port             = var.loadbalancer_target_group_port ? var.loadbalancer_target_group_port : data.aws_lb_target_group.tg[0].port
  depends_on       = [aws_route53_record.record]
}

resource "null_resource" "wait_for_instance_status" {
  provisioner "local-exec" {
    command = format(
      <<-EOT
        if [ "$(uname)" = "Linux" ]; then
          echo "executing wait-for-instance-status.sh script on Linux platform"
          sh ./terraform-aws-ec2-v2_121mount_ebs/cloud-init-scripts/wait-for-instance-status.sh "%s"
        else
          echo "executing wait-for-instance-status.ps1 script on Windows platform"
          powershell -NoProfile -ExecutionPolicy Bypass -File ./terraform-aws-ec2-v2_121mount_ebs/cloud-init-scripts/wait-for-instance-status.ps1 "%s"
        fi
      EOT
      ,
      length(aws_instance.ec2_instance) > 0 ? aws_instance.ec2_instance[0].id : "",
      length(aws_instance.ec2_instance) > 0 ? aws_instance.ec2_instance[0].id : ""
    )
  }

  depends_on = [aws_instance.ec2_instance, aws_route53_record.record]
}





