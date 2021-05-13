resource "aws_default_vpc" "default" {
    tags = {
        Name = "Terraform-managed"
    }
}

resource "aws_autoscaling_group" "bar" {
  name                      = "node-autoscaling-group-tf"
  max_size                  = 3
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 2
  force_delete              = true
  launch_configuration      = aws_launch_configuration.as_conf.name
  vpc_zone_identifier       = ["subnet-409a292b", "subnet-de0de4a3"]


  timeouts {
    delete = "15m"
  }



}

resource "aws_launch_configuration" "as_conf" {
    name          = "nodeTemplate"
    image_id      = "ami-082b957f5b3409dc9"
    instance_type = "t2.micro"
}

resource "aws_security_group" "lb_sg" {
    name        = "allow_tls"
    description = "Allow TLS inbound traffic"
    vpc_id      = aws_default_vpc.default.id

    ingress {
        description      = "TLS from VPC"
        from_port        = 443
        to_port          = 443
        protocol         = "tcp"
        cidr_blocks      = [aws_vpc.main.cidr_block]
        ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
    }

    ingress {
        description      = "TLS from VPC"
        from_port        = 80
        to_port          = 80
        protocol         = "tcp"
        cidr_blocks      = [aws_vpc.main.cidr_block]
        ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
    }


    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    tags = {
        Name = "allow_tls"
    }
}


resource "aws_lb" "lb" {
    name               = "node-lb"
    internal           = false
    load_balancer_type = "application"
    security_groups    = [aws_security_group.lb_sg.id]
    subnets            = ["subnet-5808ec25", "subnet-2b084767"]

    enable_deletion_protection = false

    tags = {
        tf = "true"
    }
}

resource "aws_lb_target_group" "tg" {
    name     = "node-starter-tg"
    port     = 4000
    protocol = "HTTP"
    vpc_id   = aws_default_vpc.default.id
}