
data "aws_vpc" "lab_vpc" {
  tags = {
    Name = "lab_vpc"
  }
}

data "aws_security_group" "ansible_server" {
  filter {
    name   = "tag:Name"
    values = ["ansible_server"]
  }
}


resource "aws_subnet" "private-subnet1" {
  vpc_id     =  data.aws_vpc.lab_vpc.id
  cidr_block = "192.168.4.0/24"
  tags = {
    Name = "Private-subnet1"
  }
}

resource "aws_subnet" "private-subnet2" {
vpc_id = data.aws_vpc.lab_vpc.id
cidr_block = "192.168.5.0/24"
}

resource "aws_db_subnet_group" "db-subnet" {
name = "db_subnet_group"
subnet_ids = [aws_subnet.private-subnet1.id, aws_subnet.private-subnet2.id]
}

resource "aws_security_group" "mysql_db" {
  name        = "mysql-server-sg"
  description = "Allow connection to the MySQL RDS server"
  vpc_id      = data.aws_vpc.lab_vpc.id
  # data.aws_vpc.talent_academy.id

  ingress {
    description      = "Allow port 3306"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    security_groups  = [data.aws_security_group.ansible_server.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "mysql-server-sg"
  }
}

resource "aws_db_instance" "rds_instance" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  db_name              = "my_db"
  username             = "master"
  password             = "master12345"
  parameter_group_name = "default.mysql8.0"
  # subnet_id = data.aws_subnet.private_subnet.id
  multi_az             = true
  skip_final_snapshot  = true
  db_subnet_group_name = "${aws_db_subnet_group.db-subnet.name}"
  vpc_security_group_ids =[aws_security_group.mysql_db.id]
}