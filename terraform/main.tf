provider "aws" {
  region = "us-east-1"
  access_key = ""
  secret_key = ""
}


resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "K8s_vpc"
  }
}


resource "aws_internet_gateway" "prod-gw" {
  vpc_id = aws_vpc.prod-vpc.id
}


resource "aws_route_table" "prod-rt" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.prod-gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id = aws_internet_gateway.prod-gw.id
  }

  tags = {
    Name = "K8s route table"
  }
}


resource "aws_subnet" "subnet-1" {
  vpc_id = aws_vpc.prod-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "K8s subnet"
  }
}


resource "aws_route_table_association" "prod-rt-as" {
  subnet_id = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-rt.id
}

resource "aws_security_group" "prod-sg" {
  name = "allow_icmp_ssh_http_https"
  description = "A new security group to allows SSH/HTTP/HTTPS traffic into the VPC"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description = "allow ICMP"
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  ingress {
    description = "allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "6443 kubernetes"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Kubernetes apiserver1"
    from_port   = 2379
    to_port     = 2379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "kubernetes apiserver"
    from_port   = 2380
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "kubernetes 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "allow SSH"
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
    Name = "K8s-sg"
  }
}


data "template_file" "instance_init_controller" {
  template = "${file("${path.module}/initial.tpl")}"

  vars = {
    hostname = "controller"
    controller_ip = "10.0.1.50"
    worker1_ip = "10.0.1.51"
    worker2_ip = "10.0.1.52"
  }
}

data "template_file" "instance_init_worker1" {
  template = "${file("${path.module}/initial.tpl")}"

  vars = {
    hostname = "worker1"
    controller_ip = "10.0.1.50"
    worker1_ip = "10.0.1.51"
    worker2_ip = "10.0.1.52"
  }
}

data "template_file" "instance_init_worker2" {
  template = "${file("${path.module}/initial.tpl")}"

  vars = {
    hostname = "worker2"
    controller_ip = "10.0.1.50"
    worker1_ip = "10.0.1.51"
    worker2_ip = "10.0.1.52"
  }
}

resource "aws_ebs_volume" "control_volume" {
  availability_zone = "us-east-1a"
  size = 40

  tags = {
    Name: "control_volume"
  }
}

resource "aws_volume_attachment" "control_volume_attachment" {
  device_name = "/dev/sdx"
  volume_id = aws_ebs_volume.control_volume.id
  instance_id = aws_instance.k8s-controller.id
}


resource "aws_instance" "k8s-worker1" {
  ami = "ami-09cd747c78a9add63"
  instance_type = "t2.medium"
  key_name = "cka_pair"
  subnet_id = aws_subnet.subnet-1.id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.prod-sg.id]
  private_ip = var.worker1_ip
  # user_data = data.template_file.instance_init_worker1.rendered
  tags = {
    Name = "k8s-worker1"
  }
}


resource "aws_instance" "k8s-worker2" {
  ami = "ami-09cd747c78a9add63"
  instance_type = "t2.medium"
  key_name = "cka_pair"
  subnet_id = aws_subnet.subnet-1.id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.prod-sg.id]
  private_ip = var.worker2_ip
  # user_data = data.template_file.instance_init_worker2.rendered
  tags = {
    Name = "k8s-worker2"
  }
}


resource "aws_instance" "k8s-controller" {
  ami = "ami-09cd747c78a9add63"
  instance_type = "t2.medium"
  key_name = "cka_pair"
  subnet_id = aws_subnet.subnet-1.id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.prod-sg.id]
  private_ip = var.controller_ip
  # user_data = data.template_file.instance_init_controller.rendered
  tags = {
    Name = "k8s-controller"
  }
}

