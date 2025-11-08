variable "project" {
  description = "Short name for resource prefixes"
  type        = string
  default     = "data-pipeline-demo"
}

variable "owner" {
  description = "Your initials or org tag"
  type        = string
  default     = "wj"
}

variable "aws_region" {
  description = "AWS region to deploy"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS named profile (e.g., wj-sandbox)"
  type        = string
  default     = null
}
variable "awswrangler_layer_arn" {
  description = "Optional AWS SDK for pandas layer ARN (Python 3.12) for your region."
  type        = string
  default     = ""
}
