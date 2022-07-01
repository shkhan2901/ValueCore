terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "tfbucketforvaluecore"
    dynamodb_table = "terraform-state-lock-dynamo"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    profile        = "myaws"
  }
}