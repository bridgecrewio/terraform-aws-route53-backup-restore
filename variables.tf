variable "aws_profile" {
  description = "The AWS profile from the credentials file that will be used to deploy this solution."
  default     = "default"
  type        = string
}

variable "region" {
  description = "The AWS region the solution will be deployed to"
  type        = string
  default     = "us-east-1"
}

variable "interval" {
  description = "The interval, in minutes, of the scheduled backup."
  type        = string
  default     = "120"
}

variable "retention_period" {
  description = "The time, in days, the backup is stored for"
  type        = string
  default     = "14"
}