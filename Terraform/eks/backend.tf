terraform {
  backend "s3" {
    bucket         = "s3-for-state-file1"
    key            = "eks/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}