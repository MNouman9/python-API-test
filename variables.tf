variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "dockerfile_path" {
  description = "Dockerfile full path"
  type = string
  default = "/home/nouman/Documents/ecs-terraform/python-API"
}

variable "container_name" {
  description = "Container name inside Task Definition"
  type = string
  default = "testpy"
}
variable "container_port" {
  description = "Specify the port on which your application is running inside the container"
  type = number
  default = 8000
}

variable "container_cpu" {
  description = "Specify the amount of cpu for the container"
  type = number
  default = 128
}

variable "container_memory" {
  description = "Specify the amount of memory for the container"
  type = number
  default = 256
}

variable "ecr_repo_name" {
  description = "ECR Repository Name"
  type        = string
  default     = "testpy-repo"
}

variable "ecs_cluster_name" {
  description = "ECS Cluster Name"
  type        = string
  default     = "testpy-cluster"
}

variable "task_definition_family" {
  description = "Task Definition Family Name"
  type        = string
  default     = "testpy-task-def"
}

variable "service_name" {
  description = "ECS Service Name"
  type        = string
  default     = "testpy-app-service"
}

variable "service_desired_count" {
  description = "ECS Service Desired Count"
  type        = number
  default     = 1
}

variable "load_balancer_name" {
  description = "Load Balancer Name"
  type = string
  default = "testpy-lb"
}