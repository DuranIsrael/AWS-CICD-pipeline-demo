resource "aws_vpc" "cicd_test" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_subnet" {
    vpc_id     = aws_vpc.cicd_test.id
    cidr_block = "10.0.1.0/24"

  tags = {
    Name = "cicd-subnet"
  }
}


