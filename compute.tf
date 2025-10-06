resource "aws_instance" "host1" {
  ami                         = var.ami-bkp-1
  instance_type               = var.instance_type_micro
  subnet_id                   = module.dev_vpc.public_subnets[0]
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]

  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name
  user_data            = file("scripts/user_data_host1.sh")

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name = "host1"
  }

  lifecycle {
    ignore_changes = [
      ami,
      user_data
    ]
  }
}

resource "aws_instance" "host2" {
  ami                         = var.ami-bkp-2
  instance_type               = var.instance_type_micro
  subnet_id                   = module.dev_vpc.public_subnets[0]
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]

  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name
  user_data            = file("scripts/user_data_host2.sh")

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name = "host2"
  }

  lifecycle {
    ignore_changes = [
      ami,
      user_data
    ]
  }
}

resource "aws_security_group" "ec2_sg" {
  name   = "dev-ec2-sg"
  vpc_id = module.dev_vpc.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks  = ["::/0"]
  }

  tags = {
    Name = "dev-ec2-sg"
  }
}

resource "aws_iam_role" "ssm_role" {
  name = "ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy_attachment" "ssm_policy" {
  name       = "ssm-managed-policy"
  roles      = [aws_iam_role.ssm_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "ssm-instance-profile"
  role = aws_iam_role.ssm_role.name
}
