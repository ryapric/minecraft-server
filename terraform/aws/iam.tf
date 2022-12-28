resource "aws_iam_instance_profile" "main" {
  role = aws_iam_role.main.name
}

resource "aws_iam_role" "main" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  managed_policy_arns = [aws_iam_policy.main.arn]
}

resource "aws_iam_policy" "main" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:Head*",
          "s3:List*",
          "s3:GetObject",
          "s3:PutObject",
        ]
        Resource = [
          "arn:aws:s3:::minecraft-server-backups-${data.aws_caller_identity.current.id}",
          "arn:aws:s3:::minecraft-server-backups-${data.aws_caller_identity.current.id}/*",
        ]
      }
    ]
  })
}
