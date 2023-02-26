resource "aws_ecs_cluster" "this" {
  name = "nginx-cluster"
}

resource "aws_ecr_repository" "this" {
  name = "nginx-repo"
}

resource "aws_ecs_task_definition" "nginx" {
  family                   = "nginx"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.nginx.arn
  cpu                      = 256
  memory                   = 512
  container_definitions    = <<EOF
  [
    {
      "name": "nginx",
      "image": "${aws_ecr_repository.this.repository_url}",
      "cpu": 256,
      "memory": 512,
      "essential": true,
      "portMappings": [
        {
          "containerPort": 80
        }
      ]
    }
  ]
  EOF

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  depends_on = [aws_iam_policy_attachment.fargate_execution]
}

resource "aws_ecs_service" "this" {
  name            = "nginx"
  task_definition = aws_ecs_task_definition.nginx.id
  cluster         = aws_ecs_cluster.this.id
  desired_count   = 1
  launch_type     = "FARGATE"


  load_balancer {
    container_name   = "nginx"
    container_port   = 80
    target_group_arn = aws_lb_target_group.this.arn
  }
  network_configuration {
    subnets          = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    assign_public_ip = true
    security_groups  = [aws_security_group.http.id]
  }

  depends_on = [aws_lb_listener.this]
}

data "aws_iam_policy_document" "task_execution_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "nginx" {
  name               = "nginx-role"
  assume_role_policy = data.aws_iam_policy_document.task_execution_role.json
}

data "aws_iam_policy_document" "task_execution_policy" {
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_policy" "policy" {
  name   = "test-policy"
  policy = data.aws_iam_policy_document.task_execution_policy.json
}

resource "aws_iam_policy_attachment" "fargate_execution" {
  name       = "fargate_execution"
  roles      = [aws_iam_role.nginx.name]
  policy_arn = aws_iam_policy.policy.arn
}