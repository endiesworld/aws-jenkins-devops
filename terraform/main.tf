
provider "aws" {
    region = var.region
}

# --- Networking: default VPC + choose one default subnet (indexable) ---
data "aws_vpc" "default" {
    default = true
}

data "aws_subnets" "default" {
    filter {
        name   = "vpc-id"
        values = [data.aws_vpc.default.id]
    }
}

data "aws_subnet" "chosen" {
    id = data.aws_subnets.default.ids[var.subnet_index]
}

# --- Security Group for App EC2 ---
resource "aws_security_group" "app_sg" {
    name        = "${var.env_prefix}-app-sg"
    description = "Security group for app EC2 managed by docker-compose"
    vpc_id      = data.aws_vpc.default.id

    # SSH only from Jenkins or your trusted CIDRs
    dynamic "ingress" {
        for_each = var.allowed_ssh_cidrs
        content {
        description = "SSH from trusted CIDR"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = [ingress.value]
        }
    }

    # HTTP (80) as needed
    dynamic "ingress" {
        for_each = var.allowed_http_cidrs
        content {
        description = "HTTP from allowed CIDR"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = [ingress.value]
        }
    }

    # HTTPS (443) as needed
    dynamic "ingress" {
        for_each = var.allowed_https_cidrs
        content {
        description = "HTTPS from allowed CIDR"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = [ingress.value]
        }
    }

    egress {
        description = "All egress"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.env_prefix}-app-sg"
    }
}

# --- IAM Role/Instance Profile (SSM + ECR read) ---
data "aws_iam_policy" "ssm_core" {
    arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy" "ecr_read_only" {
    arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role" "app_ec2_role" {
    name = "${var.env_prefix}-app-ec2-role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [{
        Effect = "Allow",
        Principal = { Service = "ec2.amazonaws.com" },
        Action   = "sts:AssumeRole"
        }]
    })
    tags = { Name = "${var.env_prefix}-app-ec2-role" }
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
    role       = aws_iam_role.app_ec2_role.name
    policy_arn = data.aws_iam_policy.ssm_core.arn
}

resource "aws_iam_role_policy_attachment" "ecr_ro" {
    role       = aws_iam_role.app_ec2_role.name
    policy_arn = data.aws_iam_policy.ecr_read_only.arn
}

resource "aws_iam_instance_profile" "app_profile" {
    name = "${var.env_prefix}-app-profile"
    role = aws_iam_role.app_ec2_role.name
}

# --- AMI (Amazon Linux 2 for simple Docker install) ---
data "aws_ami" "amzn2" {
    most_recent = true
    owners      = ["amazon"]
    filter {
        name   = "name"
        values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }
}

# --- App EC2 Instance ---
resource "aws_instance" "app_server" {
    ami                         = data.aws_ami.amzn2.id
    instance_type               = var.instance_type
    subnet_id                   = data.aws_subnet.chosen.id
    vpc_security_group_ids      = [aws_security_group.app_sg.id]
    associate_public_ip_address = true

    # Reuse an existing key pair so Jenkins can SSH and push compose files
    key_name = var.key_name

    iam_instance_profile = aws_iam_instance_profile.app_profile.name

    user_data = file("${path.module}/user_data.sh")

    root_block_device {
        volume_type = "gp3"
        volume_size = var.root_volume_size
        encrypted   = true
    }

    tags = {
        Name        = "${var.env_prefix}-app-server"
        Environment = var.env_prefix
        ManagedBy   = "Terraform"
        Role        = "AppHost"
    }
}
