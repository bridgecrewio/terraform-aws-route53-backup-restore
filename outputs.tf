output "stack_name" {
  value = "route53-backup"
}

output "function_names" {
  value = ["backup-route53", "restore-route53"]
}