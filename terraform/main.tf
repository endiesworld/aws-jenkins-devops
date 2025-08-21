provider "aws" {
    region = "us-west-2"
}

variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable avail_zone {}
variable env_prefix {}
variable my_IP {}
variable instance_type {
    default = "t2.micro" 
}
variable key_name {
    default = "jenkins-TF-EC2-key" # Key pair name to be created in AWS
    description = "Name of the key pair to be used for SSH access to the EC2 instance"
    type = string
}
variable public_key_path {
    default = "~/.ssh/id_rsa.pub" # Replace with the path to your public key
}


resource "aws_vpc" "myapp-vpc" {
    cidr_block = var.vpc_cidr_block
    tags = {
        Name = "${var.env_prefix}-vpc"
    }
}

resource "aws_subnet" "myapp-subnet-1" {
    vpc_id = aws_vpc.myapp-vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone
    tags = {
        Name = "${var.env_prefix}-subnet-1"
    }
}

resource "aws_internet_gateway" "myapp-igw" {
    vpc_id = aws_vpc.myapp-vpc.id
    tags = {
        Name = "${var.env_prefix}-igw"
    }
}

resource "aws_route_table" "myapp-route-table" {
    vpc_id = aws_vpc.myapp-vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id
    }
    tags = {
        Name = "${var.env_prefix}-route-table"
    }
}

# resource " aws_default_route_table" "myapp-default-route-table" {
#     default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id
#     route {
#         cidr_block = "0.0.0.0/0"
#         gateway_id = aws_internet_gateway.myapp-igw.id
#     }
#     tags = {
#         Name = "${var.env_prefix}-default-route-table"
#     }
# }

resource "aws_route_table_association" "myapp-subnet-association" {
    subnet_id = aws_subnet.myapp-subnet-1.id
    route_table_id = aws_route_table.myapp-route-table.id
}

resource "aws_security_group" "myapp-sg" {
    vpc_id = aws_vpc.myapp-vpc.id
    name = "${var.env_prefix}-sg"
    description = "Security group for ${var.env_prefix} environment"
    
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.my_IP] # Replace with your IP address
        description = "SSH access"
    }

    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # Replace with your IP address
        description = "HTTP access"
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow all outbound traffic"
    }
    tags = {
        Name = "${var.env_prefix}-sg"
    }
}

data "aws_ami" "latest-amazon-linux-image" {
    most_recent = true
    owners = ["amazon"]
    filter {
        name = "name"
        values = ["amzn2-ami-hvm-2*-x86_64-gp2"]
    }
    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}

# output "aws_ami_id" {
#     value = data.aws_ami.latest-amazon-linux-image.id 
# }

# resource "aws_key_pair" "ssh-key" {
#     key_name = var.key_name
#     public_key = file(var.public_key_path)
# }

resource "aws_instance" "myapp-server" {
    ami = data.aws_ami.latest-amazon-linux-image.id
    instance_type = var.instance_type

    key_name = var.key_name

    availability_zone = var.avail_zone
    subnet_id = aws_subnet.myapp-subnet-1.id
    vpc_security_group_ids = [aws_security_group.myapp-sg.id]

    associate_public_ip_address = true

    user_data = file("entry_script.sh") # Replace with your user data script path
    
    user_data_replace_on_change = true
    tags = {
        Name = "${var.env_prefix}-server"
    }
}

output "ec2_srver_public_ip" {
    value = aws_instance.myapp-server.public_ip
}
