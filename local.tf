locals {

  ecs_cluster = {
    name                         = "arc-ecs-fargate-poc"
    create                       = true
    create_cloudwatch_log_group = true
    service_connect_defaults     = {}
    settings                     = []

    configuration = {
      execute_command_configuration = {
        logging = "OVERRIDE"
        log_configuration = {
          log_group_name = "arc-poc-cluster-log-group-fargate"
        }
      }
    }
  }

  capacity_provider = {
    autoscaling_capacity_providers = {}
    use_fargate                    = true
    fargate_capacity_providers = {
      fargate_cp = {
        name = "FARGATE"
      }
    }
  }

  ecs_service = {
    create = false
  }

  ecs_services = {
    service1 = {
      ecs_cluster = {
        create = false
      }
      ecs_service = {
        cluster_name             = "arc-ecs-forgate-poc"
        service_name             = var.service_name1 #"hackathon-service-1"
        repository_name          = "884360309640.dkr.ecr.us-east-2.amazonaws.com/hackathon/service-1"
        ecs_subnets              = data.aws_subnets.private.ids
        enable_load_balancer     = true
        aws_lb_target_group_name = "hackathon-lb-tg"
        create                   = true
      }

      task = {
        tasks_desired        = 1
        launch_type          = "FARGATE"
        network_mode         = "awsvpc"
        compatibilities      = ["FARGATE"]
        container_port       = 80
        container_memory     = 1024
        container_vcpu       = 256
        container_definition = "${path.root}/container/container1_definition.json.tftpl"

      }

      lb_data = {
        listener_port     = 80
        security_group_id = aws_security_group.alb-sg.id
      }
    }

    service2 = {
      ecs_cluster = {
        create = false
      }
      ecs_service = {
        cluster_name             = "arc-ecs-forgate-poc"
        service_name             = var.service_name2 #"hackathon-service-2"
        repository_name          = "884360309640.dkr.ecr.us-east-2.amazonaws.com/hackathon/service-2"
        ecs_subnets              = data.aws_subnets.private.ids
        enable_load_balancer     = true
        aws_lb_target_group_name = "hackathon-lb-tg"
        create                   = true
      }

      task = {
        tasks_desired        = 1
        launch_type          = "FARGATE"
        network_mode         = "awsvpc"
        compatibilities      = ["FARGATE"]
        container_port       = 80
        container_memory     = 1024
        container_vcpu       = 256
       container_definition = "${path.root}/container/container2_definition.json.tftpl"

      }

      lb_data = {
        listener_port     = 80
        security_group_id = aws_security_group.alb-sg.id
      }
    }
  }

  security_groups = {
    "alb-sg" = {
      name        = "${var.namespace}-${var.environment}-alb-sg"
      description = "Allow HTTP and outbound traffic"
      rules = [
        {
          key       = "Allow HTTP from anywhere"
          type      = "ingress"
          from_port = 80
          to_port   = 80
          protocol  = "tcp"
          cidr_ipv4 = "0.0.0.0/0"
        },
        {
          key       = "Allow all outbound traffic"
          type      = "egress"
          from_port = 0
          to_port   = 0
          protocol  = "-1"
          cidr_ipv4 = "0.0.0.0/0"
        }
      ]
    }
  }
}
