resource "aws_cloudwatch_log_group" "nginx_log_group" {
  name = format("%s-%s-djangoAlbnginx", var.ApplicationName, var.EnvironmentName)
}

locals {
  nginx_log_group_name = aws_cloudwatch_log_group.nginx_log_group.name
}

resource "aws_cloudwatch_log_group" "websocket_log_group" {
  name = format("%s-%s-djangoAlbwebsocket", var.ApplicationName, var.EnvironmentName)
}

locals {
  websocket_log_group_name = aws_cloudwatch_log_group.websocket_log_group.name
}

resource "aws_cloudwatch_log_group" "app_log_group" {
  name = format("%s-%s-djangoAlbapp", var.ApplicationName, var.EnvironmentName)
}

locals {
  app_log_group_name = aws_cloudwatch_log_group.app_log_group.name
}

resource "aws_ecs_task_definition" "task_def" {
  family                   = format("%s-%s-djangoALBTaskDef", var.ApplicationName, var.EnvironmentName)
  task_role_arn            = var.task_role_arn
  execution_role_arn       = var.execution_role_arn
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  skip_destroy             = "true" 
  requires_compatibilities = ["EC2", "FARGATE"]

  container_definitions = jsonencode([
    {
      name              = "nginx"
      image             = var.nginx_image
      cpu               = 512
      memory            = 1024
      essential         = true
      command           = []
      portMappings: [
          {
              "containerPort": 80,
              "hostPort": 80,
              "protocol": "tcp"
          }
      ],
      environment: [
          {
              "name": "NGINX_WS_UPSTREAM",
              "value": "localhost:3000"
          },
          {
              "name": "NGINX_APP_UPSTREAM",
              "value": "localhost:8000"
          },
          {
              "name": "NGINX_AWS_VPC_CIDR",
              "value": var.public_vpc_cidr
          }
      ],     
      ulimits = [
        {
          name       = "nofile"
          softlimit = 30000
          hardlimit = 40000
        }
      ]
      logconfiguration = {
        logdriver = "awslogs"
        options    = {
          "awslogs-group"         = local.nginx_log_group_name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "nginx"
        }
      }
    },
    {
      name              = "websockets"
      image             = var.websockets_image
      cpu               = 512
      memory            = 1024
      essential         = var.django_ALB_websockets_enabled
      command           = ["websockets"]
      portMappings: [
          {
              "containerPort": 3000,
              "hostPort": 3000,
              "protocol": "tcp"
          }
      ],
      environment   = [
        for key, value in var.environment_variables :
        {
          name  = key
          value = value
        }
      ] 
      secrets     = [
        for key, secret_arn in var.secrets :
        {
          name       = key
          valueFrom = secret_arn
        }
      ]     
      ulimits = [
        {
          name       = "nofile"
          softlimit = 30000
          hardlimit = 40000
        }
      ]
      logconfiguration = {
        logdriver = "awslogs"
        options    = {
          "awslogs-group"         = local.websocket_log_group_name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "websockets"
        }
      }
    },
    {
      name              = "app"
      image             = var.app_image
      cpu               = 1024
      memory            = 2048
      essential         = true
      command           = ["app"]
      portMappings: [
          {
              "containerPort": 8000,
              "hostPort": 8000,
              "protocol": "tcp"
          }
      ],
      environment   = [
        for key, value in var.environment_variables :
        {
          name  = key
          value = value
        }
      ] 
      secrets     = [
        for key, secret_arn in var.secrets :
        {
          name       = key
          valueFrom = secret_arn
        }
      ]     
      ulimits = [
        {
          name       = "nofile"
          softlimit = 30000
          hardlimit = 40000
        }
      ]
      logconfiguration = {
        logdriver = "awslogs"
        options    = {
          "awslogs-group"         = local.app_log_group_name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "app"
        }
      }
    }
  ])
  # lifecycle {
  #   create_before_destroy = true
  # }
}

resource "aws_lb" "ALB" {
  name               = format("%s-%s-ALB", var.ApplicationName, var.EnvironmentName)
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.djangoALB-LB-sg
  subnets            = var.public_subnets

  enable_deletion_protection = false

  access_logs {
    bucket  = var.alb_logs_bucket
    prefix  = format("%s-%s-djangoALB", var.ApplicationName, var.EnvironmentName)
    enabled = true
  }
}

resource "aws_lb_target_group" "target_group" {
  name     = format("%s-%s-ALB", var.ApplicationName, var.EnvironmentName)
  port     = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id   = var.public_vpc_id
  deregistration_delay = 60  # <== reduce to 1 min  
  depends_on      = [aws_lb.ALB]

  stickiness {
    type         = "lb_cookie"
    enabled      = false
  }

  health_check {
    path                = "/status/"
    port                = "80"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 15
    healthy_threshold   = 2
    unhealthy_threshold = 5
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.ALB.arn
  port              = 443
  protocol          = "HTTPS"
  depends_on      = [aws_lb_target_group.target_group]

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }

  ssl_policy = "ELBSecurityPolicy-2016-08"
  certificate_arn = var.alb_service_cert
}

resource "aws_ecs_service" "ecs_service" {
  name            = format("%s-%s-djangoALB", var.ApplicationName, var.EnvironmentName)
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.task_def.arn
  desired_count   = var.desired_count
  depends_on      = [aws_lb_target_group.target_group]
  launch_type     = "FARGATE"
  enable_execute_command = "true"
  wait_for_steady_state  = "true"
  health_check_grace_period_seconds = 30

  lifecycle {
    ignore_changes = [desired_count]
  }


  network_configuration {
    subnets          = var.private_subnets
    security_groups  = var.djangoALBService-sg
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = "nginx"
    container_port   = 80
  }


  # dynamic "service_registries" {
  #   for_each = var.enable_service_discovery_albservice ? [1] : []
  #   content {
  #     registry_arn = aws_service_discovery_service.service_discovery_service[0].arn 
  #   }
  # }



  service_registries {
    registry_arn = aws_service_discovery_service.service_discovery_service.arn
  }

}

locals {
  cluster_name = element(split("/", var.ecs_cluster_name), length(split("/", var.ecs_cluster_name)) - 1)
}

resource "aws_appautoscaling_target" "ecs_target" {
  count = var.enable_autoscaling ? 1 : 0
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${local.cluster_name}/${aws_ecs_service.ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
} 

resource "aws_appautoscaling_policy" "scaling_policy" {
  count = var.enable_autoscaling ? 1 : 0
  depends_on = [ aws_ecs_service.ecs_service ]
  name               = "step-scaling-policy"
  service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace
  resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    target_value       = 50.0
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_in_cooldown  = 300
    scale_out_cooldown = 180
  }
}


resource "aws_service_discovery_service" "service_discovery_service" {
  # count = var.enable_service_discovery_albservice ? 1 : 0 
  name              = "django.alb"

  dns_config {
    namespace_id      = var.aws_service_discovery_private_dns_namespace
    dns_records {
      ttl  = 15
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
  health_check_custom_config {
    failure_threshold = 1
  }  
}


