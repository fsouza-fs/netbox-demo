data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  common_env_vars = [
    { name = "DB_WAIT_DEBUG", value = "1" },
    { name = "CORS_ORIGIN_ALLOW_ALL", value = "True" },
    { name = "DB_HOST", value = aws_db_instance.netbox_postgres.address },
    { name = "DB_NAME", value = var.netbox_db_name },
    { name = "DB_PASSWORD", value = var.netbox_db_password },
    { name = "DB_USER", value = var.netbox_db_username },
    { name = "EMAIL_FROM", value = var.netbox_email },
    { name = "EMAIL_PASSWORD", value = "" },
    { name = "EMAIL_PORT", value = "25" },
    { name = "EMAIL_SERVER", value = "localhost" },
    { name = "EMAIL_SSL_CERTFILE", value = "" },
    { name = "EMAIL_SSL_KEYFILE", value = "" },
    { name = "EMAIL_TIMEOUT", value = "5" },
    { name = "EMAIL_USERNAME", value = "netbox" },
    { name = "EMAIL_USE_SSL", value = "false" },
    { name = "EMAIL_USE_TLS", value = "false" },
    { name = "GRAPHQL_ENABLED", value = "true" },
    { name = "HOUSEKEEPING_INTERVAL", value = "86400" },
    { name = "MEDIA_ROOT", value = "/opt/netbox/netbox/media" },
    { name = "METRICS_ENABLED", value = "false" },
    { name = "REDIS_CACHE_DATABASE", value = "1" },
    { name = "REDIS_CACHE_HOST", value = aws_elasticache_replication_group.redis.primary_endpoint_address },
    { name = "REDIS_CACHE_INSECURE_SKIP_TLS_VERIFY", value = "false" },
    { name = "REDIS_CACHE_SSL", value = "false" },
    { name = "REDIS_DATABASE", value = "0" },
    { name = "REDIS_HOST", value = aws_elasticache_replication_group.redis.primary_endpoint_address },
    { name = "REDIS_INSECURE_SKIP_TLS_VERIFY", value = "false" },
    { name = "REDIS_SSL", value = "false" },
    { name = "RELEASE_CHECK_URL", value = "https://api.github.com/repos/netbox-community/netbox/releases" },
    { name = "SECRET_KEY", value = var.netbox_secret_key },
    { name = "WEBHOOKS_ENABLED", value = "true" },
    { name = "no_proxy", value = "localhost,127.0.0.1,.internal,.local" },
    { name = "ALLOWED_HOSTS", value = join(" ", ["netbox.domain.net", "localhost", aws_lb.ecs_alb.dns_name, var.vpc_cidr]) },
    { name  = "SUPERUSER_NAME", value = var.netbox_superuser_name },
    { name  = "SUPERUSER_EMAIL", value = var.netbox_superuser_email },
    { name  = "SUPERUSER_PASSWORD", value = var.netbox_superuser_pass },
    { name  = "SKIP_SUPERUSER", value = "false" }
  ]
}

resource "aws_ecs_cluster" "ecs_cluster" {
 name = var.cluster_name
}

resource "aws_ecs_capacity_provider" "ecs_capacity_provider" {
 name = "netbox-cp"

 auto_scaling_group_provider {
   auto_scaling_group_arn = aws_autoscaling_group.ecs_asg.arn

   managed_scaling {
     maximum_scaling_step_size = 1000
     minimum_scaling_step_size = 1
     status                    = "ENABLED"
     target_capacity           = 3
   }
 }
}

resource "aws_ecs_cluster_capacity_providers" "example" {
 cluster_name = aws_ecs_cluster.ecs_cluster.name

 capacity_providers = [aws_ecs_capacity_provider.ecs_capacity_provider.name]

 default_capacity_provider_strategy {
   base              = 1
   weight            = 100
   capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
 }
}

data "aws_iam_policy" "ecsExecutionRolePolicy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "ecsExecutionRolePolicy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "ecs_task_logging_policy" {
  name        = "ecs-task-logging-policy"
  description = "Allow ECS tasks to write logs to CloudWatch"
  policy      = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource": "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/ecs/netbox:*"
      }
    ]
  })
}

resource "aws_iam_role" "ecsExecutionRole" {
  name               = "ecsExecutionRole"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ecsExecutionRolePolicy.json
}

resource "aws_iam_role_policy_attachment" "ecsExecutionPolicy" {
  role       = aws_iam_role.ecsExecutionRole.name
  policy_arn = data.aws_iam_policy.ecsExecutionRolePolicy.arn
}

resource "aws_iam_role_policy_attachment" "ecsLoggingPolicy" {
  role       = aws_iam_role.ecsExecutionRole.name
  policy_arn = aws_iam_policy.ecs_task_logging_policy.arn
}

resource "aws_cloudwatch_log_group" "ecs_netbox_log_group" {
  name = "/ecs/netbox"
  
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "netbox" {
 family             = "netbox-task"
 network_mode       = "awsvpc"
 execution_role_arn = aws_iam_role.ecsExecutionRole.arn
 cpu                = 1024
 runtime_platform {
   operating_system_family = "LINUX"
   cpu_architecture        = "X86_64"
 }
 
 container_definitions = jsonencode([
    {
      readonly_root_filesystem = false
      name        = "netbox"
      image       = var.netbox_image
      cpu         = 256
      memory      = 512
      essential   = true
      environment = local.common_env_vars
      portMappings = [
        {
          name = "http"
          containerPort = 8080
          protocol      = "tcp"
        }
      ]
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8080/login/ || exit 1"]
        interval = 30
        timeout  = 5
        retries  = 3
        startPeriod = 300
      }
      mountPoints = [
        { sourceVolume = "configuration", containerPath = "/etc/netbox/config", readOnly = false },
        { sourceVolume = "media-files", containerPath = "/opt/netbox/netbox/media", readOnly = false },
        { sourceVolume = "reports-files", containerPath = "/opt/netbox/netbox/reports", readOnly = false },
        { sourceVolume = "scripts-files", containerPath = "/opt/netbox/netbox/scripts", readOnly = false },
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/netbox"
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "netbox"
        }
      }
    },
    {
      name        = "netbox-worker"
      image       = var.netbox_image
      cpu         = 256
      memory      = 512
      essential   = false
      environment = local.common_env_vars
      command     = ["/opt/netbox/venv/bin/python", "/opt/netbox/netbox/manage.py", "rqworker"]
      dependsOn = [
        {
          containerName = "netbox"
          condition     = "HEALTHY"
        }
      ]
      healthCheck = {
        command     = ["CMD-SHELL", "ps -aux | grep -v grep | grep -q rqworker || exit 1"]
        startPeriod = 20
        timeout     = 3
        interval    = 15
      }
    },
    {
      name        = "netbox-housekeeping"
      image       = var.netbox_image
      cpu         = 256
      memory      = 512
      essential   = false
      environment = local.common_env_vars
      command     = ["/opt/netbox/housekeeping.sh"]
      dependsOn = [
        {
          containerName = "netbox"
          condition     = "HEALTHY"
        }
      ]
      healthCheck = {
        command     = ["CMD-SHELL", "ps -aux | grep -v grep | grep -q housekeeping || exit 1"]
        startPeriod = 20
        timeout     = 3
        interval    = 15
      }
    }
  ])

  volume {
    name = "configuration"
    host_path = "/home/ec2-user/configuration"
  }

  volume {
    name = "media-files"
    host_path = "/home/ec2-user/media"
  }

  volume {
    name = "reports-files"
    host_path = "/home/ec2-user/reports"
  }

  volume {
    name = "scripts-files"
    host_path = "/home/ec2-user/scripts"
  }
}

resource "aws_ecs_service" "netbox_service" {
 name            = var.netbox-service
 cluster         = aws_ecs_cluster.ecs_cluster.id
 task_definition = aws_ecs_task_definition.netbox.arn
 desired_count   = 1
 health_check_grace_period_seconds = 600

 network_configuration {
   subnets         = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
   security_groups = [aws_security_group.netbox_ecs_sg.id]
 }

 force_new_deployment = true
 placement_constraints {
   type = "distinctInstance"
 }

 triggers = {
   redeployment = true
 }

 capacity_provider_strategy {
   capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
   weight            = 100
 }

 load_balancer {
   target_group_arn = aws_lb_target_group.ecs_tg.arn
   container_name   = var.netbox_container_name
   container_port   = 8080
 }

 service_registries {
    registry_arn   = aws_service_discovery_service.this.arn
 }

 lifecycle {
  ignore_changes = [task_definition]
 }

 depends_on = [aws_autoscaling_group.ecs_asg]
}

resource "aws_service_discovery_private_dns_namespace" "private" {
  name        = var.domain_name
  description = "Private dns namespace for service discovery"
  vpc         = aws_vpc.main.id
}

resource "aws_service_discovery_service" "this" {
  name = var.netbox-service
  force_destroy = true

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.private.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.ecs_cluster.name
}
