resource "aws_codedeploy_app" "app" {
  compute_platform = "ECS"
  name             = "app"
}

resource "aws_codedeploy_deployment_group" "deployment_group" {
  app_name               = aws_codedeploy_app.app.name
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  deployment_group_name  = "example"
  service_role_arn       = aws_iam_role.role.arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = data.aws_ecs_serivce.ecs.name
    service_name = data.aws_ecs_service.ecs_service.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.example.arn]
      }

      target_group {
        name = data.aws_alb_target_group.blue.name
      }

      target_group {
        name = data.aws_alb_target_group.green.name
      }
    }
  }
}

resource "aws_iam_role" "role" {
  name               = "codedeploy-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_codedeploy.json
}

data "aws_iam_policy_document" "assume_role_codedeploy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
  }
}
resource "aws_iam_role_policy_attachment" "AWSCodeDeployRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = aws_iam_role.role.name
}


resource "aws_iam_role_policy_attachment" "AWSCodeDeployRoleECS" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRoleForECS"
  role       = aws_iam_role.role.name
}

