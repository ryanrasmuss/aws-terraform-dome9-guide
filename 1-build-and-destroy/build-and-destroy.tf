provider "aws" {
    profile = "default"
    region = "us-west-1"
}

resource "aws_instance" "example" {
    ami = "ami-03caa3f860895f82e"
    instance_type = "t2.micro"
    key_name = "your-key-here"
}
