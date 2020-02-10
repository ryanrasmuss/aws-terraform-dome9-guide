# Getting started with AWS, Terraform, and Dome9

### Login to your AWS Account

Register and sign into your AWS console at https://console.aws.amazon.com

Generate an AWS key pair for your EC2 instances. We will refer this as ``your-aws-key`` in this guide.

Install AWS CLI. Instructions can be found here: https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html

Once installed, run ``aws configure`` and add your key pairs. You can find this information in the AWS web console under ``My Security Credentials``.

We will need you to have ``$HOME/.aws/`` defined with a credentials file. Terraform will use this location.

### Register Dome9

Sign up at https://secure.dome9.com

Click the '+' sign next to the AWS symbol to add your AWS account. Follow the instructions on Dome9.

### Install Terraform

Find your relevant terraform binary from https://www.terraform.io/downloads.html

Make sure to create the relevant PATH variable. Linux/Mac instructions [here](https://stackoverflow.com/questions/14637979/how-to-permanently-set-path-on-linux-unix) and instructions for windows [here](https://stackoverflow.com/questions/1618280/where-can-i-set-path-to-make-exe-on-windows)

### First Exercise: Build and Destroy

See directory: ``1-build-and-destroy/``

We will create the following ``tf`` file

```
provider "aws" {
    profile = "default"
    region = "us-west-1"
}

resource "aws_instance" "example" {
    ami = "ami-03caa3f860895f82e"
    instance_type = "t2.micro"
    key_name = "your-aws-key"
}
```

Change the ``key_name`` parameter for the name of your aws key.

Run ``terraform plan`` to check for errors. If there are none, run ``terraform apply``.

You should be able to ssh in your new instance via: ``ssh -i your-aws-key ec2-user@public_ip``

Run ``terraform destroy``

### Second Exercise: Build Infrastructure

Here you will learn the building blocks of deploying an AWS environment.

Refer to the directory: ``2-build-infrastructure/``.

We will create the following ``tf`` file

```
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
    key_name = "your-ec2-key"
    vpc_security_group_ids = ["${aws_security_group.application-sg.id}" ]
    subnet_id = "${aws_subnet.application-subnet-1.id}"
    associate_public_ip_address = true

    tags = {
        Name = "application-instance"
    }
}
```

Takeaways:

- What are the building blocks of a basic AWS deployment? Note the dependencies
- How does terraform save state?
- How do you change a component in the deployment? Do you have to redeploy everything?

Run ``terraform destroy``

### Build a simple application with provisioning

Refer to ``3-provision/``

We will use the ``user_data`` field to have our new instance run commands when deployed.

Now you can make a http request to this instance and you should see a web page.

### Build an Application with Terraform

Refer to ``4-build-app/``



