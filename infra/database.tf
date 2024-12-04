resource "aws_db_subnet_group" "default" {
  name       = "main1"
  subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
}

resource "aws_docdb_subnet_group" "default" {
  name       = "main2"
  subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
}

resource "aws_db_instance" "netbox_postgres" {
  db_subnet_group_name = aws_db_subnet_group.default.name
  allocated_storage    = 5
  max_allocated_storage = 20
  engine               = "postgres"
  engine_version       = "16"
  instance_class       = "db.t4g.micro"
  db_name                 = var.netbox_db_name
  username             = var.netbox_db_username
  password             = var.netbox_db_password
  parameter_group_name = aws_db_parameter_group.netbox_pg.name
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible = true

  tags = {
    Name = "netbox-database"
  }
}

resource "aws_security_group" "db" {
  vpc_id = aws_vpc.main.id

  name_prefix = "db-"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

    security_groups = [aws_security_group.netbox_ecs_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_parameter_group" "netbox_pg" {
  name        = "netbox-postgres-params"
  family      = "postgres16"
  description = "Custom parameter group for NetBox"

  parameter {
      name  = "rds.force_ssl"
      value = "0"
      apply_method = "pending-reboot" # Requires a reboot to take effect
    }
}

output "rds_address" {
  value = aws_db_instance.netbox_postgres.address
}
