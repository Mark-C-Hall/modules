resource "aws_db_instance" "mysql" {
  identifier_prefix   = "${var.db_instance_name}-mysql"
  engine              = "mysql"
  allocated_storage   = 10
  instance_class      = "db.t3.micro"
  skip_final_snapshot = true
  db_name             = "mydb"

  username = var.db_username
  password = var.db_password
}

variable "db_username" {
  description = "The username for the database"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "The password for the database"
  type        = string
  sensitive   = true
}

variable "db_instance_name" {
  description = "The name to use for the database instance"
  type        = string
}

output "address" {
  value       = aws_db_instance.mysql.address
  description = "MySQL Database Address"
}

output "port" {
  value       = aws_db_instance.mysql.port
  description = "MySQL Database Port"
}
