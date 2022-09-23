data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "backup_target" {
  bucket_prefix = "route53-backup-data-${data.aws_caller_identity.current.account_id}-"
}

resource "aws_s3_bucket_lifecycle_configuration" "remove-after-retention" {
  bucket = aws_s3_bucket.backup_target.bucket
  rule {
    id     = "s3 _deletion"
    status = "Enabled"
    filter {}
    expiration {
      days = var.retention_period
    }
  }
}

data "aws_iam_policy_document" "backup-route53" {
  statement {
    sid = "1"

    actions = [
      "s3:PutEncryptionConfiguration",
      "s3:PutObject",
      "s3:PutLifecycleConfiguration",
      "s3:PutBucketPolicy",
      "s3:CreateBucket",
      "s3:ListBucket",
      "s3:PutBucketVersioning"
    ]

    resources = [
      aws_s3_bucket.backup_target.arn,
      "${aws_s3_bucket.backup_target.arn}/*"
    ]
  }
  statement {
    sid = "2"

    actions = [
      "route53:GetHealthCheck",
      "route53:ListHealthChecks",
      "route53:GetHostedZone",
      "route53:ListHostedZones",
      "route53:ListHostedZonesByName",
      "route53:ListResourceRecordSets",
      "route53:ListTagsForResource",
      "route53:ListTagsForResources"
    ]

    resources = ["*"]
  }

}

module "backup-route53-lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "4.0.2"

  function_name = "backup-route53"
  description = "Backs up Route53 regularly to a bucket"
  handler = "backup_route53.handle"
  runtime = "python3.7"

  policy_json = data.aws_iam_policy_document.backup-route53.json
  attach_policy_json = true

  source_path = [
    "${path.module}/backup_route53.py",
    "${path.module}/route53_utils.py"
  ]

  environment_variables = {
    BUCKET = aws_s3_bucket.backup_target.bucket
  }
}

resource "aws_lambda_permission" "cw-timed-exec" {
  statement_id = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.backup-route53-lambda.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.timed-exec.arn
}

resource "aws_cloudwatch_event_rule" "timed-exec" {
  name = "every-${var.interval}-minutes"
  description = "Fires every ${var.interval} minutes"
  schedule_expression = "rate(${var.interval} minutes)"
}

resource "aws_cloudwatch_event_target" "timed-exec" {
  rule = aws_cloudwatch_event_rule.timed-exec.name
  target_id = module.backup-route53-lambda.lambda_function_name
  arn = module.backup-route53-lambda.lambda_function_arn
}

data "aws_iam_policy_document" "restore-route53" {
  statement {
    sid = "1"

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.backup_target.arn}/*"
    ]
  }

  statement {
    sid = "2"

    actions = [
      "ec2:DescribeVpcs"
    ]

    resources = ["*"]
  }

  statement {
    sid = "3"

    actions = [
      "route53:GetHealthCheck",
      "route53:ListHealthChecks",
      "route53:GetHostedZone",
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
      "route53:ListTagsForResource",
      "route53:ListTagsForResources",
      "route53:CreateHostedZone",
      "route53:GetHealthCheck",
      "route53:ChangeResourceRecordSets",
      "route53:ListTagsForResource",
      "route53:ListTagsForResources",
      "route53:CreateHealthCheck",
      "route53:AssociateVPCWithHostedZone",
      "route53:ChangeTagsForResource"
    ]

    resources = ["*"]
  }
}

module "restore-route53-lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "4.0.2"

  function_name = "restore-route53"
  description = "Restores route53 from backup"
  handler = "backup_route53.handle"
  runtime = "python3.7"

  policy_json = data.aws_iam_policy_document.backup-route53.json
  attach_policy_json = true

  source_path = [
    "${path.module}/backup_route53.py",
    "${path.module}/route53_utils.py"
  ]


  environment_variables = {
    BUCKET = aws_s3_bucket.backup_target.bucket
  }
}