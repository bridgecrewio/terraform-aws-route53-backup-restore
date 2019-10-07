resource "null_resource" "deploy_route53_backup_and_restore" {
  triggers = {
    build = timestamp()
  }

  provisioner "local-exec" {
    working_dir = path.module
    command     = "npm i && sls deploy --backup-interval ${var.interval} --retention-period ${var.retention_period} --region ${var.region} --aws-profile ${var.aws_profile}"
  }
}

resource "null_resource" "remove_route53_backup_and_restore" {
  provisioner "local-exec" {
    when        = "destroy"
    working_dir = path.module
    command     = "npm i && sls remove --backup-interval ${var.interval} --retention-period ${var.retention_period} --region ${var.region} --aws-profile ${var.aws_profile}"
  }
}
