###############################################################################
# 
# VPC, WEB HOST(S) AND DOMAIN NAME
#
###############################################################################

# REGION ######################################################################
provider "aws" {
  region = "us-east-1"
}


# VPC #########################################################################
resource "aws_vpc" "main" {
  cidr_block       = "${var.vpc_main_cidr_block}"
  instance_tenancy = "default"

  tags             = {
    Name           = "main"
  }
}

resource "aws_subnet" "subnetMain" {
  count             = "${length(data.aws_availability_zones.all.names)}"
  vpc_id            = "${aws_vpc.main.id}"
  availability_zone = "${data.aws_availability_zones.all.names[count.index]}"

  cidr_block        = "${element(var.secondary_cidr_blocks, count.index)}"
}

resource "aws_internet_gateway" "igw" {
  vpc_id            = "${aws_vpc.main.id}"

  tags              = {
    Name            = "igw-main"
  }
}

resource "aws_route" "rt-igw-main" {
  route_table_id         = "${aws_vpc.main.default_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.igw.id}"
}


# ASG #########################################################################
resource "aws_launch_configuration" "awsUbuntuInstance" {
  image_id                    = "ami-43a15f3e"
  instance_type               = "t2.micro"
  security_groups             = ["${aws_security_group.webHost.id}"]
  associate_public_ip_address = "false"

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p "${var.server_http_port}" &
              EOF

  lifecycle {
    create_before_destroy     = true
  }
}

resource "aws_security_group" "webHost" {
  name                    = "web-host-sg-ingress"
  vpc_id                  = "${aws_vpc.main.id}"
          
  ingress {          
    from_port             = "${var.server_http_port}"
    to_port               = "${var.server_http_port}"
    protocol              = "tcp"
    cidr_blocks           = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "web" {
  launch_configuration  = "${aws_launch_configuration.awsUbuntuInstance.id}"
  vpc_zone_identifier   = ["${aws_subnet.subnetMain.*.id}"]
  depends_on            = ["aws_vpc.main"]
  load_balancers        = ["${aws_elb.web.name}"]
  health_check_type     = "ELB"
 
  min_size              = 6
  max_size              = 6

  tag {
    key                 = "Name"
    value               = "asg-web"
    propagate_at_launch = true
  }
}


# ELB #########################################################################
resource "aws_elb" "web" {
  name                  = "elb-web"
  subnets               = ["${aws_subnet.subnetMain.*.id}"]
  security_groups       = ["${aws_security_group.elb.id}"]
  
  listener {  
    lb_port             = 80
    lb_protocol         = "http"
    instance_port       = "${var.server_http_port}"
    instance_protocol   = "http"
  }  

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    target              = "HTTP:${var.server_http_port}/"
  }
}

resource "aws_security_group" "elb" {
  name          = "elb-sg-ingress-egress"
  vpc_id        = "${aws_vpc.main.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" #  all protocols and ports allowed
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# ROUTE 53 ####################################################################
resource "aws_route53_record" "www" {
  zone_id                  = "${var.r53_zone_id}"
  name                     = "${var.r53_domain_name}"
  type                     = "A"
  alias {
    name                   = "${aws_elb.web.dns_name}"
    zone_id                = "${aws_elb.web.zone_id}"
    evaluate_target_health = "false"
  }
}


# OUTPUT ######################################################################
output "elb_dns_name" {
  value = "${aws_elb.web.dns_name}"
}
