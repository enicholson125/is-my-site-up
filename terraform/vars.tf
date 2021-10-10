variable "monitor_schedule" {
  default     = "0 10 * * *"
  type        = string
  description = "Cron style schedule at which to trigger the Cloud Key rotator"
}

variable "monitor_schedule_time_zone" {
  default     = "Europe/London"
  type        = string
  description = "The time zone for the scheduler job to schedule in"
}

variable "deploying_accounts" {
  default     = []
  type        = list(string)
  description = "List of accounts which will be deploying the CKR terraform. This needs to be given if you are not giving the deploying accounts the iam.serviceAccountUser permission for the whole project"
}

variable "gmail_account" {
  type        = string
  description = "Gmail account to send monitor emails from"
}

variable "urls_to_check" {
  type        = string
  description = "Comma separated list of URLs to monitor"
}

variable "email_to_alert" {
  type        = string
  description = "The email address to contact if a URL is down"
}
