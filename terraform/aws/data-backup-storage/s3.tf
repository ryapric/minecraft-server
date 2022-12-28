data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "main" {
  bucket = "minecraft-server-backups-${data.aws_caller_identity.current.id}"
}

resource "aws_s3_bucket_acl" "main" {
  bucket = aws_s3_bucket.main.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "main" {
  bucket = aws_s3_bucket.main.bucket

  rule {
    id     = "delete_stale_world_data"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 3
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}
