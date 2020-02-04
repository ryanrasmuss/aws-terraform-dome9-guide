provider "aws" {
    profile = "default"
    region = "us-west-1"
}

# Step 1. Build VPC

resource "aws_vpc" "application-vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true

    tags = {
        Name = "application vpc"
    }
}

# Step 2. Build Subnet

resource "aws_subnet" "application-subnet-1" {
    vpc_id = "${aws_vpc.application-vpc.id}"
    cidr_block = "10.0.0.0/24"
    availability_zone = "us-west-1b"

    tags = {
        Name = "application subnet 1"
    }
}

# Step 3. Build IGW

resource "aws_internet_gateway" "application-igw" {
    vpc_id = "${aws_vpc.application-vpc.id}"

    tags = {
        Name = "application igw"
    }
}

# Step 4. Build Route Table

resource "aws_route_table" "application-rtb" {
    vpc_id = "${aws_vpc.application-vpc.id}"

    # Point default to igw
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.application-igw.id}"
    }

    tags = {
        Name = "application rtb"
    }
}

# Step 5. Associate Route Table to Subnet

resource "aws_route_table_association" "application-rtb-association" {
    subnet_id = "${aws_subnet.application-subnet-1.id}"
    route_table_id = "${aws_route_table.application-rtb.id}"
}

# Step 6. Build Security Group

resource "aws_security_group" "application-sg" {
    name = "application-sg"
    description = "application requires http and ssh"
    vpc_id = "${aws_vpc.application-vpc.id}"

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 80
        to_port     = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "application-sg"
    }
}

# Step 7. Build Instnace or Application

resource "aws_instance" "application-instance" {
    ami = "ami-03caa3f860895f82e"
    instance_type = "t2.micro"
    key_name = "your-key-here"
    vpc_security_group_ids = ["${aws_security_group.application-sg.id}" ]
    subnet_id = "${aws_subnet.application-subnet-1.id}"
    associate_public_ip_address = true

    user_data = <<-EOF
#!/bin/bash
echo "Hello World!" >> index.html
sudo yum update -y
sudo yum install git -y
sudo yum install python3 -y
sudo python3 -m http.server 80 &
EOF
    
    tags = {
        Name = "application-instance"
    }

    provisioner "local-exec" {
        command = "echo ${aws_instance.application-instance.public_ip} > ip_address.txt"
    }
}
