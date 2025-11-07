variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "simple-web-app"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "domain_name" {
  description = "Domain name for the application (optional)"
  type        = string
  default     = ""
}

variable "backend_image_tag" {
  description = "Docker image tag for backend"
  type        = string
  default     = "latest"
}

variable "backend_container_port" {
  description = "Port that the backend container listens on"
  type        = number
  default     = 3000
}

variable "backend_cpu" {
  description = "CPU units for backend task"
  type        = number
  default     = 256
}

variable "backend_memory" {
  description = "Memory (in MiB) for backend task"
  type        = number
  default     = 512
}

variable "backend_desired_count" {
  description = "Desired number of backend tasks"
  type        = number
  default     = 2
}

variable "frontend_build_path" {
  description = "Path to frontend build files"
  type        = string
  default     = "../frontend/dist"
}

variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring and alarms"
  type        = bool
  default     = true
}

variable "notification_email" {
  description = "Email for notifications (optional)"
  type        = string
  default     = ""
}