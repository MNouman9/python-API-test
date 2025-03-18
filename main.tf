################################################################################
## ECR
################################################################################
resource "aws_ecr_repository" "my_ecr_repo" {
  name = var.ecr_repo_name
}

#############
# ECR Policy
####################
resource "aws_ecr_repository_policy" "my_repo_policy" {
  repository = aws_ecr_repository.my_ecr_repo.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowPull",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability"
      ]
    }
  ]
}
EOF
}

################################################################################
## Docker Image Build & Push
################################################################################
data "aws_caller_identity" "current" {}

resource "null_resource" "docker_packaging" {
  provisioner "local-exec" {
    command = <<EOF
    aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.us-east-1.amazonaws.com
    docker build -t ${aws_ecr_repository.my_ecr_repo.repository_url}:latest ${var.dockerfile_path}
    docker push ${aws_ecr_repository.my_ecr_repo.repository_url}:latest
    EOF
  }
  depends_on = [aws_ecr_repository.my_ecr_repo]
}

################################################################################
## ECS CLuster
################################################################################
resource "aws_ecs_cluster" "my_cluster" {
  name = var.ecs_cluster_name
}

#############
# Task Definition
####################
resource "aws_ecs_task_definition" "app_task" {
  family                   = var.task_definition_family
  container_definitions    = <<DEFINITION
  [
    {
      "name": "${var.container_name}",
      "image": "${aws_ecr_repository.my_ecr_repo.repository_url}",
      "essential": true,
      "portMappings": [
        {
          "containerPort": ${var.container_port},
          "hostPort": ${var.container_port}
        }
      ],
      "memory": ${var.container_memory},
      "cpu": ${var.container_cpu}
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = var.container_memory
  cpu                      = var.container_cpu
  execution_role_arn       = "${aws_iam_role.ecsTaskExecutionRole.arn}"
}

#############
# App Service
####################
resource "aws_ecs_service" "app_service" {
  name            = var.service_name
  cluster         = "${aws_ecs_cluster.my_cluster.id}"
  task_definition = "${aws_ecs_task_definition.app_task.arn}"
  launch_type = "FARGATE"
  desired_count   = var.service_desired_count

  load_balancer {
    target_group_arn = "${aws_lb_target_group.target_group.arn}"
    container_name   = var.container_name
    container_port   = var.container_port
  }

  network_configuration {
    subnets          = ["${aws_default_subnet.default_subnet_a.id}", "${aws_default_subnet.default_subnet_b.id}"]
    assign_public_ip = true
    security_groups  = ["${aws_security_group.service_security_group.id}"]
  }
}

#############
# Service Security Group
####################
resource "aws_security_group" "service_security_group" {
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#############
# IAM Role
####################
resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
}

#############
# IAM Policy
####################
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = "${aws_iam_role.ecsTaskExecutionRole.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

################################################################################
## VPC
################################################################################
resource "aws_default_vpc" "default_vpc" {
}

#############
# Subnets
####################
resource "aws_default_subnet" "default_subnet_a" {
  availability_zone = "us-east-1a"
}

resource "aws_default_subnet" "default_subnet_b" {
  availability_zone = "us-east-1b"
}

################################################################################
## Load Balancer - ALB
################################################################################
resource "aws_alb" "application_load_balancer" {
  name               = var.load_balancer_name
  load_balancer_type = "application"
  subnets = [
    "${aws_default_subnet.default_subnet_a.id}",
    "${aws_default_subnet.default_subnet_b.id}"
  ]

  security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
}

#############
# Security Group
####################
resource "aws_security_group" "load_balancer_security_group" {
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#############
# Target Group
####################
resource "aws_lb_target_group" "target_group" {
  name        = "target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "${aws_default_vpc.default_vpc.id}"
}

#############
# Listener
####################
resource "aws_lb_listener" "listener" {
  load_balancer_arn = "${aws_alb.application_load_balancer.arn}"
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.target_group.arn}"
  }
}