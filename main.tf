################################################################################
## defaults
################################################################################

module "tags" {
  source  = "sourcefuse/arc-tags/aws"
  version = "1.2.6"

  environment = terraform.workspace
  project     = "terraform-aws-arc-ecs"

  extra_tags = {
    Example = "True"
  }
}

################################################################################
## ecs cluster
################################################################################


module "arc-ecs_ecs-cluster" {
  source  = "sourcefuse/arc-ecs/aws"
  version = "2.0.0"
  ecs_cluster       = local.ecs_cluster
  capacity_provider = local.capacity_provider
  ecs_service       = local.ecs_service
  tags              = module.tags.tags
}

################################################################################
## ecs services and task
################################################################################


module "arc-ecs_ecs-service" {
  for_each = local.ecs_services

  source           = "sourcefuse/arc-ecs/aws"
  version          = "2.0.0"
  ecs_cluster      = each.value.ecs_cluster
  ecs_cluster_name = local.ecs_cluster.name
  ecs_service      = each.value.ecs_service
  task             = each.value.task
  lb_data          = each.value.lb_data
  vpc_id           = data.aws_vpc.vpc.id
  target_group_arn = aws_lb_target_group.hackathon.arn
  environment      = var.environment
  tags             = module.tags.tags
  depends_on       = [module.arc-ecs_ecs-cluster, aws_lb.hackathon]

}




resource "aws_security_group" "alb-sg" {
  name        = local.security_groups["alb-sg"].name
  description = local.security_groups["alb-sg"].description
  vpc_id      = data.aws_vpc.vpc.id

  tags = module.tags.tags
}

resource "aws_security_group_rule" "alb-sg-rules" {
  count = length(local.security_groups["alb-sg"].rules)

  security_group_id = aws_security_group.alb-sg.id
  type              = local.security_groups["alb-sg"].rules[count.index].type
  from_port         = local.security_groups["alb-sg"].rules[count.index].from_port
  to_port           = local.security_groups["alb-sg"].rules[count.index].to_port
  protocol          = local.security_groups["alb-sg"].rules[count.index].protocol
  cidr_blocks       = [local.security_groups["alb-sg"].rules[count.index].cidr_ipv4]
  description       = local.security_groups["alb-sg"].rules[count.index].key
}


resource "aws_lb" "hackathon" {
  name               = "hackathon-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb-sg.id]
  subnets            = data.aws_subnets.public.ids

  enable_deletion_protection = true

/*  access_logs {
    bucket  = aws_s3_bucket.lb_logs.id
    prefix  = "test-lb"
    enabled = true
  }
*/

  tags = module.tags.tags
  
}


resource "aws_lb_target_group" "hackathon" {
  name        = "hackathon-lb-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.vpc.id
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.hackathon.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.hackathon.arn
  }
}