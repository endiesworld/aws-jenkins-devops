variable "region" {
    default = "us-west-2"
}

variable "avail_zone" {
    description = "Availability Zone for the EC2 instance"
    default     = "us-west-2a"
}

variable "subnet_index" {
    description = "Index of the subnet to use from the default VPC"
    type        = number
    default     = 1
}

variable "env_prefix" {
    description = "Prefix for environment resources"
    type        = string
    default     = "app-dev-env"
}

variable "instance_type" {
    description = "EC2 instance type"
    default     = "t2.micro"
}

variable "key_name" {
    description = "Name of the EC2 key pair"
    type        = string
    default     = "jenkins-TF-EC2-key"
}

variable "my_IP" {
    description = "Your IP address with CIDR notation"
    type        = string
    default = "108.35.175.17/32"
}

variable "allowed_ssh_cidrs" {
    description = "CIDRs allowed to SSH (22) into the app EC2 (e.g., Jenkins public /32)"
    type        = list(string)
    default     = ["108.35.175.17/32", "0.0.0.0/32"]
}

variable "allowed_http_cidrs" {
    description = "CIDRs allowed to reach HTTP (80). Use [] to keep closed."
    type        = list(string)
    default     = ["108.35.175.17/32"]
}

variable "allowed_https_cidrs" {
    description = "CIDRs allowed to reach HTTPS (443). Use [] to keep closed."
    type        = list(string)
    default     = ["108.35.175.17/32"]
}

variable "root_volume_size" {
    description = "Root volume size in GiB"
    type        = number
    default     = 20
}