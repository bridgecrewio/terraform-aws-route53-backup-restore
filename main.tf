data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "backup_target" {
  bucket_prefix = "route53-backup-data-${data.aws_caller_identity.current.account_id}-"
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

  source_path = "backup_route53.py"

  layers = [
    module.lambda-layer.lambda_layer_arn
  ]

  allowed_triggers = {
    cloudwatch_scheduled = {
      principal = "events.amazonaws.com"

    }
  }
  environment_variables = {
    BUCKET = aws_s3_bucket.backup_target.bucket
  }
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

  source_path = "backup_route53.py"

  layers = [
    module.lambda-layer.lambda_layer_arn
  ]

  environment_variables = {
    BUCKET = aws_s3_bucket.backup_target.bucket
  }
}

module "lambda-layer" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "4.0.2"

  create_layer = true

  layer_name = "route53_utils"
  compatible_runtimes = ["python3.7"]

  source_path = "route53_utils.py"
}