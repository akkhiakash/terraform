locals {
  api_service_sg_ids = var.create_xservice ? [aws_security_group.APIService-sg[0].id] : []
}



resource "aws_security_group" "DBCluster-sg" {
  count = var.existing_db_cluster_sg == "" ? 1 : 0
  name        = format("%s-%s-DBCluster-sg", var.ApplicationName, var.EnvironmentName)
  description = "Security group for ${format("%s-%s-DBCluster-sg", var.ApplicationName, var.EnvironmentName)}"
  vpc_id      = var.private_vpc_id
  
  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    security_groups =[aws_security_group.pgbouncer-sg.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "bastion-ec2-sg" {
  count       = var.create_bastion_instance ? 1 : 0
  name        = format("%s-%s-bastion-ec2-sg", var.ApplicationName, var.EnvironmentName)
  description = "Security group for ${format("%s-%s-bastion-ec2-sg", var.ApplicationName, var.EnvironmentName)}"
  vpc_id      = var.private_vpc_id
  
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = var.bastion_ec2_cidrs
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    ignore_changes = [
      ingress,
      egress
    ]
  }
}

resource "aws_security_group" "ALB-LB-sg" {
  name        = format("%s-%s-ALB-LB-sg", var.ApplicationName, var.EnvironmentName)
  description = "Security group for ${format("%s-%s-ALB-LB-sg", var.ApplicationName, var.EnvironmentName)}"
  vpc_id      = var.public_vpc_id
  
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    prefix_list_ids = var.prefix_list_ids
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  lifecycle {
    ignore_changes = [
      ingress,
      egress
    ]
  }
}

resource "aws_security_group" "API-LB-sg" {
  count = var.create_xservice ? 1 : 0
  name        = format("%s-%s-ALB-LB-sg", var.ApplicationName, var.EnvironmentName)
  description = "Security group for ${format("%s-%s-ALB-LB-sg", var.ApplicationName, var.EnvironmentName)}"
  vpc_id      = var.private_vpc_id
  
  ingress {
    from_port = 9000
    to_port = 9000
    protocol = "tcp"
    prefix_list_ids = var.xserviceprivate_prefix_list_ids
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  lifecycle {
    ignore_changes = [
      ingress,
      egress
    ]
  }

}




resource "aws_security_group" "APIService-sg" {
  count = var.create_xservice ? 1 : 0
  name        = format("%s-%s-ALBService-sg", var.ApplicationName, var.EnvironmentName)
  description = "Security group for ${format("%s-%s-ALBService-sg", var.ApplicationName, var.EnvironmentName)}"
  vpc_id      = var.private_vpc_id
  
  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = var.private_vpc_cidr
    security_groups = [aws_security_group.API-LB-sg[0].id] 
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  lifecycle {
    ignore_changes = [
      ingress,
      egress
    ]
  }

}



resource "aws_security_group" "Butler-LB-sg" {
  name        = format("%s-%s-Butler-LB-sg", var.ApplicationName, var.EnvironmentName)
  description = "Security group for ${format("%s-%s-Butler-LB-sg", var.ApplicationName, var.EnvironmentName)}"
  vpc_id      = var.public_vpc_id
  
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    prefix_list_ids = var.prefix_list_ids

  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    ignore_changes = [
      ingress,
      egress
    ]
  }
}

resource "aws_security_group" "pgbouncer-sg" {
  name        = format("%s-%s-pgbouncer-sg", var.ApplicationName, var.EnvironmentName)
  description = "Security group for ${format("%s-%s-pgbouncer-sg", var.ApplicationName, var.EnvironmentName)}"
  vpc_id      = var.private_vpc_id
  
  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    security_groups = concat([aws_security_group.ButlerService-sg.id,aws_security_group.workerService-sg.id,aws_security_group.ALBService-sg.id],local.api_service_sg_ids)
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ButlerService-sg" {
  name        = format("%s-%s-ButlerService-sg", var.ApplicationName, var.EnvironmentName)
  description = "Security group for ${format("%s-%s-djangoButlerService-sg", var.ApplicationName, var.EnvironmentName)}"
  vpc_id      = var.private_vpc_id
  
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = var.public_vpc_cidr
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "workerService-sg" {
  name        = format("%s-%s-workerService-sg", var.ApplicationName, var.EnvironmentName)
  description = "Security group for ${format("%s-%s-workerService-sg", var.ApplicationName, var.EnvironmentName)}"
  vpc_id      = var.private_vpc_id
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ALBService-sg" {
  name        = format("%s-%s-ALBService-sg", var.ApplicationName, var.EnvironmentName)
  description = "Security group for ${format("%s-%s-ALBService-sg", var.ApplicationName, var.EnvironmentName)}"
  vpc_id      = var.private_vpc_id
  
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks =var.public_vpc_cidr
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  lifecycle {
    ignore_changes = [
      ingress,
      egress
    ]
  }

}

resource "aws_security_group" "redis-sg" {
  count = var.deploy_redis ? 1 : 0
  name        = format("%s-%s-redis-sg", var.ApplicationName, var.EnvironmentName)
  description = "Security group for ${format("%s-%s-redis-sg", var.ApplicationName, var.EnvironmentName)}"
  vpc_id      = var.private_vpc_id

  ingress {
    from_port = 6379
    to_port = 6379
    protocol = "tcp"
    security_groups = concat([aws_security_group.ButlerService-sg.id,aws_security_group.workerService-sg.id,aws_security_group.ALBService-sg.id],local.api_service_sg_ids)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rabbitMQ-sg" {
  name        = format("%s-%s-rabbitMQ-sg", var.ApplicationName, var.EnvironmentName)
  description = "Security group for ${format("%s-%s-rabbitMQ-sg", var.ApplicationName, var.EnvironmentName)}"
  vpc_id      = var.private_vpc_id

  ingress {
    from_port = 5671
    to_port = 5671
    protocol = "tcp"
    security_groups = concat([aws_security_group.ButlerService-sg.id,aws_security_group.workerService-sg.id,aws_security_group.ALBService-sg.id, aws_security_group.etl_lambda_sg.id],local.api_service_sg_ids)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  lifecycle {
    ignore_changes = [
      ingress,
      egress
    ]
  }
}

# resource "aws_vpc_security_group_ingress_rule" "existing_db_cluster_to_pgbouncer_sg" {
#   count = var.existing_db_cluster_sg != "" ? 1 : 0
#   security_group_id = var.existing_db_cluster_sg
#   referenced_security_group_id = aws_security_group.pgbouncer-sg.id
#   from_port   = 5432
#   ip_protocol = "tcp"
#   to_port     = 5432
# }

# resource "aws_vpc_security_group_ingress_rule" "existing_db_cluster_to_pgbouncer_sg" {
#   for_each = var.existing_db_cluster_sg != "" ? { "rule" = var.existing_db_cluster_sg } : {}

#   security_group_id             = each.value
#   referenced_security_group_id = aws_security_group.pgbouncer-sg.id
#   from_port                    = 5432
#   ip_protocol                  = "tcp"
#   to_port                      = 5432


#   lifecycle {
#     ignore_changes = [
#       security_group_id,
#       referenced_security_group_id,
#       from_port,
#       to_port,
#       ip_protocol
#     ]
#   }

#   depends_on = [
#     aws_security_group.pgbouncer-sg
#   ]
# }


resource "aws_vpc_security_group_ingress_rule" "existing_db_cluster_to_pgbouncer_sg" {
  for_each = var.existing_db_cluster_sg != "" ? { "rule" = var.existing_db_cluster_sg } : {}

  security_group_id             = each.value
  referenced_security_group_id = aws_security_group.pgbouncer-sg.id
  from_port                    = 5432
  ip_protocol                  = "tcp"
  to_port                      = 5432

  depends_on = [
    aws_security_group.pgbouncer-sg
  ]
}



resource "aws_security_group" "etl_lambda_sg" {
  name        = format("%s-%s-etl-lambda-sg", var.ApplicationName, var.EnvironmentName)
  description = "Security group for ${format("%s-%s-etl-lambda", var.ApplicationName, var.EnvironmentName)}"
  vpc_id      = var.private_vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

  


