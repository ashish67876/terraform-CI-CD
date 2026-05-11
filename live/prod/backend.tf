terraform {
  required_version = ">= 1.5.0"
  
  backend "s3" {
    bucket         = "mycompany-terraform-state-prod"
    key            = "prod/vpc/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks-prod"
  }
}