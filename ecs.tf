data "aws_iam_policy_document" "ecs_task_execution_role" {
  version = "2012-10-17"

  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "ecs-staging-execution-role-${var.env_suffix}"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "template_file" "service" {
  template = file(var.tpl_path)

  vars = {
    region             = var.region
    aws_ecr_repository = aws_ecr_repository.repo.repository_url
    tag                = "latest"
    container_port     = 8080
    host_port          = 8080
    app_name           = var.app_name
    env_suffix         = var.env_suffix
  }
}

data "template_file" "service_point" {
  template = file(var.tpl_path)

  vars = {
    region             = var.region
    aws_ecr_repository = aws_ecr_repository.point_repo.repository_url
    tag                = "latest"
    container_port     = 8080
    host_port          = 8080
    app_name           = var.app_name
    env_suffix         = var.env_suffix
  }
}

resource "aws_ecs_task_definition" "service" {
  family                   = "service-staging-${var.env_suffix}"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = 256
  memory                   = 512
  requires_compatibilities = ["FARGATE"]
  container_definitions    = data.template_file.service.rendered

  tags = {
    Environment = var.env_suffix
    Application = var.app_name
  }
}

resource "aws_ecs_task_definition" "service_point" {
  family                   = "service-point-staging-${var.env_suffix}"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = 256
  memory                   = 512
  requires_compatibilities = ["FARGATE"]
  container_definitions    = data.template_file.service_point.rendered

  tags = {
    Environment = var.env_suffix
    Application = var.app_name
  }
}

resource "aws_ecs_cluster" "staging" {
  name = "service-ecs-cluster-${var.env_suffix}"
}

resource "aws_ecs_service" "staging" {
  name                  = "staging"
  cluster               = aws_ecs_cluster.staging.id
  task_definition       = aws_ecs_task_definition.service.arn
  desired_count         = length(data.aws_availability_zones.available.names)
  force_new_deployment  = true
  launch_type           = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.private.*.id
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.staging.arn
    container_name   = var.app_name
    container_port   = var.container_port
  }

  depends_on = [
    aws_lb_listener.http_forward,
    aws_iam_role_policy_attachment.ecs_task_execution_role,
  ]

  tags = {
    Environment = var.env_suffix
    Application = var.app_name
  }
}

resource "aws_ecs_service" "staging_point" {
  name                  = "staging-point"
  cluster               = aws_ecs_cluster.staging.id
  task_definition       = aws_ecs_task_definition.service_point.arn
  desired_count         = length(data.aws_availability_zones.available.names)
  force_new_deployment  = true
  launch_type           = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.private.*.id
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.staging.arn
    container_name   = var.app_name
    container_port   = var.container_port
  }

  depends_on = [
    aws_lb_listener.http_forward,
    aws_iam_role_policy_attachment.ecs_task_execution_role,
  ]

  tags = {
    Environment = var.env_suffix
    Application = var.app_name
  }
}