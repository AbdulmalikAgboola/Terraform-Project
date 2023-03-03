terraform {
  backend "s3" {
    bucket = "maleekbucket-011"
    key    = "terraform.tfstate"
    region = "us-west-2"
  }
}