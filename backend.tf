terraform {
  backend "s3" {
    bucket  = "ditf-s3-storage"
    encrypt = true
    key     = "terraform.tfstate"
    region  = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}