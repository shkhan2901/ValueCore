resource "aws_s3_bucket" "tfbucketforvaluecore" {

  bucket = "tfbucketforvaluecore"
}

resource "aws_s3_bucket_acl" "tfbucketforvaluecore_acl" {
  bucket = aws_s3_bucket.tfbucketforvaluecore.id
  acl    = "private"
}