locals {
  prefix = "${var.project}-${var.owner}"
}

# --- S3 buckets for lake zones ---
resource "aws_s3_bucket" "landing" {
  bucket = "${local.prefix}-landing"
}

resource "aws_s3_bucket" "clean" {
  bucket = "${local.prefix}-clean"
}

resource "aws_s3_bucket" "curated" {
  bucket = "${local.prefix}-curated"
}

# --- Block public access ---
resource "aws_s3_bucket_public_access_block" "landing" {
  bucket                  = aws_s3_bucket.landing.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "clean" {
  bucket                  = aws_s3_bucket.clean.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "curated" {
  bucket                  = aws_s3_bucket.curated.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- Versioning ---
resource "aws_s3_bucket_versioning" "landing" {
  bucket = aws_s3_bucket.landing.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_versioning" "clean" {
  bucket = aws_s3_bucket.clean.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_versioning" "curated" {
  bucket = aws_s3_bucket.curated.id
  versioning_configuration { status = "Enabled" }
}

# --- Server-side encryption (SSE-S3) ---
resource "aws_s3_bucket_server_side_encryption_configuration" "landing" {
  bucket = aws_s3_bucket.landing.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "clean" {
  bucket = aws_s3_bucket.clean.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "curated" {
  bucket = aws_s3_bucket.curated.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# --- Lifecycle (optional): expire landing after 30 days ---
resource "aws_s3_bucket_lifecycle_configuration" "landing" {
  bucket = aws_s3_bucket.landing.id
  rule {
    id     = "expire-landing-after-30-days"
    status = "Enabled"
    filter {}
    expiration { days = 30 }
  }
}

# --- Glue Catalog database ---
resource "aws_glue_catalog_database" "lake" {
  name = replace("${local.prefix}-lake", "/[^a-z0-9_]/", "_")
}

############################################
# Lambda CSV -> Parquet (uses awswrangler layer)
############################################

data "archive_file" "csv_to_parquet_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../apps/lambda_csv_to_parquet"
  output_path = "${path.module}/../apps/lambda_csv_to_parquet.zip"
}

data "aws_iam_policy_document" "lambda_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com",
        "glue.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "${local.prefix}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
}

# Base Lambda permissions: read landing, read/write clean, logs
data "aws_iam_policy_document" "lambda_policy_doc" {
  # Landing bucket: list the bucket
  statement {
    sid       = "LandingList"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.landing.arn]
  }

  # Landing bucket: read objects
  statement {
    sid       = "LandingReadObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.landing.arn}/*"]
  }

  # Clean bucket: list the bucket
  statement {
    sid       = "CleanList"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.clean.arn]
  }

  # Clean bucket: read/write objects
  statement {
    sid       = "CleanReadWriteObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${aws_s3_bucket.clean.arn}/*"]
  }

  # Logs
  statement {
    sid       = "Logs"
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambda_policy" {
  name   = "${local.prefix}-lambda-policy"
  policy = data.aws_iam_policy_document.lambda_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# NEW: let Glue crawler use this role
resource "aws_iam_role_policy_attachment" "lambda_attach_glue_service" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# --- DLQ (SQS) and permission for Lambda to send to it ---
resource "aws_sqs_queue" "csv_to_parquet_dlq" {
  name = "csv-to-parquet-dlq"
}

data "aws_iam_policy_document" "lambda_to_dlq" {
  statement {
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.csv_to_parquet_dlq.arn]
  }
}

resource "aws_iam_policy" "lambda_to_dlq" {
  name   = "${local.prefix}-lambda-to-dlq"
  policy = data.aws_iam_policy_document.lambda_to_dlq.json
}

resource "aws_iam_role_policy_attachment" "attach_lambda_to_dlq" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_to_dlq.arn
}

resource "aws_lambda_function" "csv_to_parquet" {
  function_name    = "${local.prefix}-csv-to-parquet"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.csv_to_parquet_zip.output_path
  source_code_hash = data.archive_file.csv_to_parquet_zip.output_base64sha256
  timeout          = 60
  memory_size      = 1024

  # attach awswrangler layer if provided
  layers = var.awswrangler_layer_arn == "" ? [] : [var.awswrangler_layer_arn]

  environment {
    variables = {
      CLEAN_BUCKET = aws_s3_bucket.clean.bucket
    }
  }

  # dead-letter queue
  dead_letter_config {
    target_arn = aws_sqs_queue.csv_to_parquet_dlq.arn
  }
}

# Allow S3 to invoke Lambda
resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.csv_to_parquet.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.landing.arn
}

# S3 -> Lambda notification (CSV suffix)
resource "aws_s3_bucket_notification" "landing_to_lambda" {
  bucket = aws_s3_bucket.landing.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.csv_to_parquet.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".csv"
  }

  depends_on = [aws_lambda_permission.allow_s3_invoke]
}

############################################
# CloudWatch alarm on Lambda errors
############################################
resource "aws_cloudwatch_metric_alarm" "lambda_error_alarm" {
  alarm_name          = "${aws_lambda_function.csv_to_parquet.function_name}_Errors"
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  dimensions          = { FunctionName = aws_lambda_function.csv_to_parquet.function_name }
  # alarm_actions = [aws_sns_topic.ops_alerts.arn] # optional
}

############################################
# Glue crawler for clean zone
############################################
resource "aws_glue_crawler" "clean_crawler" {
  name          = "${local.prefix}-clean-crawler"
  role          = aws_iam_role.lambda_role.arn
  database_name = aws_glue_catalog_database.lake.name

  s3_target { path = "s3://${aws_s3_bucket.clean.bucket}/" }

  configuration = jsonencode({
    Version       = 1.0,
    CrawlerOutput = { Partitions = { AddOrUpdateBehavior = "InheritFromTable" } }
  })
}
