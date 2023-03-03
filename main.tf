resource "aws_vpc" "maleek_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "maleek_vpc"
  }
}

resource "aws_internet_gateway" "maleek_internet_gateway" {
  vpc_id = aws_vpc.maleek_vpc.id
  tags = {
    Name = "maleek_internet_gateway"
  }
}


resource "aws_route_table" "maleek-route-table-public" {
  vpc_id = aws_vpc.maleek_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.maleek_internet_gateway.id
  }
  tags = {
    Name = "maleek-route-table-public"
  }
}


resource "aws_route_table_association" "maleek-public-subnet1-association" {
  subnet_id      = aws_subnet.maleek-public-subnet1.id
  route_table_id = aws_route_table.maleek-route-table-public.id
}

# Associate public subnet 2 with public route table

resource "aws_route_table_association" "maleek-public-subnet2-association" {
  subnet_id      = aws_subnet.maleek-public-subnet2.id
  route_table_id = aws_route_table.maleek-route-table-public.id
}


resource "aws_subnet" "maleek-public-subnet1" {
  vpc_id                  = aws_vpc.maleek_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-west-2a"
  tags = {
    Name = "maleek-public-subnet1"
  }
}
# Create Public Subnet-2

resource "aws_subnet" "maleek-public-subnet2" {
  vpc_id                  = aws_vpc.maleek_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-west-2b"
  tags = {
    Name = "maleek-public-subnet2"
  }
}

resource "aws_network_acl" "maleek-network_acl" {
  vpc_id     = aws_vpc.maleek_vpc.id
  subnet_ids = [aws_subnet.maleek-public-subnet1.id, aws_subnet.maleek-public-subnet2.id]

   ingress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}

resource "aws_security_group" "maleek-load_balancer_sg" {
  name        = "maleek-load-balancer-sg"
  description = "Security group for the load balancer"
  vpc_id      = aws_vpc.maleek_vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    
  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "maleek-security-grp-rule" {
  name        = "allow_ssh_http_https"
  description = "Allow SSH, HTTP and HTTPS inbound traffic for private instances"
  vpc_id      = aws_vpc.maleek_vpc.id

 ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.maleek-load_balancer_sg.id]
  }

 ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.maleek-load_balancer_sg.id]
  }


  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
   
  }
  tags = {
    Name = "maleek-security-grp-rule"
  }
}


resource "aws_instance" "maleek1" {
  ami             = "ami-00712dae9a53f8c15"
  instance_type   = "t2.micro"
  key_name        = "terraform-project"
  security_groups = [aws_security_group.maleek-security-grp-rule.id]
  subnet_id       = aws_subnet.maleek-public-subnet1.id
  availability_zone = "us-west-2a"
  tags = {
    Name   = "maleek-1"
    source = "terraform"
  }
}
# creating instance 2
 resource "aws_instance" "maleek2" {
  ami             = "ami-00712dae9a53f8c15"
  instance_type   = "t2.micro"
  key_name        = "terraform-project"
  security_groups = [aws_security_group.maleek-security-grp-rule.id]
  subnet_id       = aws_subnet.maleek-public-subnet2.id
  availability_zone = "us-west-2b"
  tags = {
    Name   = "maleek-2"
    source = "terraform"
  }
}
# creating instance 3
resource "aws_instance" "maleek3" {
  ami             = "ami-00712dae9a53f8c15"
  instance_type   = "t2.micro"
  key_name        = "terraform-project"
  security_groups = [aws_security_group.maleek-security-grp-rule.id]
  subnet_id       = aws_subnet.maleek-public-subnet1.id
  availability_zone = "us-west-2a"
  tags = {
    Name   = "maleek-3"
    source = "terraform"
  }
}


resource "local_file" "Ip_address" {
  filename = "/mnt/c/Users/USER/TERRAFORM/host-inventory"
  content  = <<EOT
${aws_instance.maleek1.public_ip}
${aws_instance.maleek2.public_ip}
${aws_instance.maleek3.public_ip}
  EOT
}


resource "aws_lb" "maleek-load-balancer" {
  name               = "maleek-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.maleek-load_balancer_sg.id]
  subnets            = [aws_subnet.maleek-public-subnet1.id, aws_subnet.maleek-public-subnet2.id]


  #enable_cross_zone_load_balancing = true

  enable_deletion_protection = false
  depends_on                 = [aws_instance.maleek1, aws_instance.maleek2, aws_instance.maleek3]
}


resource "aws_lb_target_group" "maleek-target-group" {
  name     = "maleek-target-group"
  target_type = "instance"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.maleek_vpc.id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "maleek-listener" {
  load_balancer_arn = aws_lb.maleek-load-balancer.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.maleek-target-group.arn
  }
}
# Create the listener rule

resource "aws_lb_listener_rule" "maleek-listener-rule" {
  listener_arn = aws_lb_listener.maleek-listener.arn
  priority     = 1
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.maleek-target-group.arn
  }
  condition {
    path_pattern {
      values = ["/"]
    }
  }
}


resource "aws_lb_target_group_attachment" "maleek-target-group-attachment1" {
  target_group_arn = aws_lb_target_group.maleek-target-group.arn
  target_id        = aws_instance.maleek1.id
  port             = 80
}
 
resource "aws_lb_target_group_attachment" "maleek-target-group-attachment2" {
  target_group_arn = aws_lb_target_group.maleek-target-group.arn
  target_id        = aws_instance.maleek2.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "maleek-target-group-attachment3" {
  target_group_arn = aws_lb_target_group.maleek-target-group.arn
  target_id        = aws_instance.maleek3.id
  port             = 80 
  
  }