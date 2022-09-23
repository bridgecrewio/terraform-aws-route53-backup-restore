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