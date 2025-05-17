provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "allow_ssh_mysql" {
  name        = "allow_ssh_mysql"
  description = "Allow SSH and MySQL"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "MySQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0" # Ubuntu 20.04 LTS in us-east-1
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.allow_ssh_mysql.id]
  key_name      = var.key_pair_name

  tags = {
    Name = "WebServer-01"
  }
}

# resource "aws_db_instance" "mysql" {
#   allocated_storage    = 20
#   engine               = "mysql"
#   engine_version       = "8.0"
#   instance_class       = "db.t3.micro"
#   db_name              = "etechbackend"
#   username             = "admin"
#   password             = var.db_password
#   skip_final_snapshot  = true
#   publicly_accessible  = true
#   vpc_security_group_ids = [aws_security_group.allow_ssh_mysql.id]
#   db_subnet_group_name = aws_db_subnet_group.dbsubnet.name
# }

# resource "aws_db_subnet_group" "dbsubnet" {
#   name       = "main-db-subnet"
#   subnet_ids = [aws_subnet.public.id]
# }
