resource "aws_key_pair" "lamp-key-pair" {
  key_name   = "lamp-key-pair"
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096

}

resource "local_file" "lamp-key-pair" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "lamp-key-pair"
}


resource "aws_default_vpc" "default" {

}


data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

resource "aws_launch_template" "aws-launch-template" {
  name     = "aws-launch-template"
  image_id = data.aws_ami.amazon-linux-2.id
  #image_id               = data.aws_ami.amazon-linux-2.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.lamp-key-pair.key_name
  vpc_security_group_ids = [aws_security_group.aws-sg-lampserver.id]
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "aws-webserver-demo"
    }
  }
  user_data = filebase64("userdata.tpl")
}

resource "aws_autoscaling_group" "aws-autoscaling-group" {
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  desired_capacity   = 2
  min_size           = 2
  max_size           = 3

  launch_template {
    id      = aws_launch_template.aws-launch-template.id
    version = "$Latest"
  }
}