resource "aws_instance" "host1" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type_micro
  subnet_id              = module.dev_vpc.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

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
}

resource "aws_instance" "host2" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type_micro
  subnet_id              = module.dev_vpc.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

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
}

resource "aws_security_group" "ec2_sg" {
  name   = "dev-ec2-sg"
  vpc_id = module.dev_vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
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

#resource "aws_instance" "dev4" {
#  ami                    = data.aws_ami.amazon_linux_2.id
#  instance_type          = var.instance_type_micro
#  subnet_id              = module.dev_vpc.private_subnets[0]
#  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
#
#  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name
#  user_data            = file("scripts/user_data_base.sh")
#
#  root_block_device {
#    volume_size           = 20
#    volume_type           = "gp3"
#    delete_on_termination = true
#  }
#
#  tags = {
#    Name = "dev4"
#  }
#}