output "DBCluster-sg" {
    value = var.existing_db_cluster_sg == "" ? aws_security_group.DBCluster-sg[0].id : null
}

output "bastion-ec2-sg" {
    value = var.create_bastion_instance ? aws_security_group.bastion-ec2-sg[0].id : null
}

output "ALB-LB-sg" {
    value = aws_security_group.djangoALB-LB-sg.id
}

output "Butler-LB-sg" {
    value = aws_security_group.djangoButler-LB-sg.id
}

output "pgbouncer-sg" {
    value = aws_security_group.pgbouncer-sg.id
}

output "ButlerService-sg" {
    value = aws_security_group.djangoButlerService-sg.id
}

output "workerService-sg" {
    value = aws_security_group.djangoworkerService-sg.id
}

output "ALBService-sg" {
    value = aws_security_group.djangoALBService-sg.id
}

output "redis-sg" {
  value = var.deploy_redis ? aws_security_group.redis-sg[0].id : null
}

output "rabbitMQ-sg" {
    value = aws_security_group.rabbitMQ-sg.id
}

output "etl_lambda_sg" {
    value = var.create_etl_lambda ? aws_security_group.etl_lambda_sg.id : null
}

output "API-LB-sg" {
    value = var.create_xservice ? aws_security_group.API-LB-sg[0].id : null
}

output "APIService-sg" {
    value = var.create_xservice ? aws_security_group.APIService-sg[0].id : null
}

