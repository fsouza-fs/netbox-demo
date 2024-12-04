resource "aws_s3_bucket" "config_bucket" {
  bucket = "netbox-configuration-files-bucket"
  
  tags = {
    Name = "NetBoxConfigBucket"
  }
}

locals {
  config_files = fileset("../configuration", "**")
}

resource "aws_s3_object" "config_files" {
  for_each   = local.config_files
  bucket     = aws_s3_bucket.config_bucket.id
  key        = each.value
  source     = "../configuration/${each.value}"
  content_type = "text/x-python"
}

resource "aws_iam_policy" "ecs_task_s3_access" {
  name        = "ecs-task-s3-access-policy"
  description = "Allows ECS tasks to access the S3 bucket for configuration files"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "s3:ListBucket",
        Resource = "${aws_s3_bucket.config_bucket.arn}"
      },
      {
        Effect   = "Allow",
        Action   = [
          "s3:GetObject"
        ],
        Resource = "${aws_s3_bucket.config_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_s3_access" {
  role       = aws_iam_role.ecsExecutionRole.name
  policy_arn = aws_iam_policy.ecs_task_s3_access.arn
}

resource "aws_iam_role_policy_attachment" "ecs_instance_profile_s3_access" {
  role       = aws_iam_role.ecsInstanceRole.name
  policy_arn = aws_iam_policy.ecs_task_s3_access.arn
}
