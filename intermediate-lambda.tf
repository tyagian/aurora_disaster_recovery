

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda.py"
  output_path = "${path.module}/lambda_function_payload.zip"
}

# AWS Lambda Function
resource "aws_lambda_function" "BackupCopyManagerLambda" {
  provider         = aws.aws-intermediate
  function_name    = "BackupCopyManager-${var.vault_intermediate_name}"
  description      = "Lambda function to automate copy of resources to destinationBackupVaultArn"
  handler          = "lambda.lambda_handler"
  runtime          = "python3.9"
  memory_size      = 128
  timeout          = 300
  filename         = "${path.module}/lambda_function_payload.zip"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  role             = aws_iam_role.BackupCopyManagerRole.arn

  environment {
    variables = {
      COPY_TO_ACCOUNT_TAG = "CopyToAccount"
      COPY_TO_REGION_TAG  = "CopyToRegion"
      COPY_TO_VAULT_TAG   = "CopyToVault"
    }
  }
}

# IAM Role
resource "aws_iam_role" "BackupCopyManagerRole" {
  provider = aws.aws-intermediate
  name     = "BackupCopyManagerRole-${var.vault_intermediate_name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })

  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"]

  inline_policy {
    name = "BackupCopyManagerLambda-Cloudwatch-Policy-${var.vault_intermediate_name}"

    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [{
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      }]
    })
  }

  inline_policy {
    name = "BackupCopyManagerLambda-PassRole-Policy-${var.vault_intermediate_name}"

    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [{
        Effect = "Allow",
        Action = [
          "iam:PassRole"
        ],
        Resource = "arn:aws:iam::${var.source_account_id}:role/service-role/AWSBackupDefaultServiceRole"
      }]
    })
  }

  inline_policy {
    name = "BackupCopyManagerLambda-BackupPermissions-Policy-${var.vault_intermediate_name}"

    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [{
        Effect = "Allow",
        Action = [
          "backup:StartCopyJob",
          "backup:ListTags",
          "backup:DescribeRecoveryPoint"
        ],
        Resource = "*"
      }]
    })
  }
}

# Lambda Function Permission
resource "aws_lambda_permission" "ProcessCopyJobStatusEventRuleInvokePermission" {
  provider      = aws.aws-intermediate
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.BackupCopyManagerLambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ProcessCopyJobStatusEventRule.arn
}

# AWS CloudWatch Event Rule
resource "aws_cloudwatch_event_rule" "ProcessCopyJobStatusEventRule" {
  provider    = aws.aws-intermediate
  name        = "CopyJobStatusEvent-${var.vault_intermediate_name}"
  description = "Rule to direct AWS Backup Copy Job Events to Handler Lambda"
  state       = "ENABLED"

  event_pattern = jsonencode({
    source        = ["aws.backup"],
    "detail-type" = ["Copy Job State Change"],
    detail = {
      state                     = ["COMPLETED"],
      destinationBackupVaultArn = ["${aws_backup_vault.rBackupVault-intermediate.arn}"]
    }
  })
}

# AWS CloudWatch Event Target (for Lambda function)
resource "aws_cloudwatch_event_target" "ProcessCopyJobStatusEventRuleTarget" {
  provider  = aws.aws-intermediate
  rule      = aws_cloudwatch_event_rule.ProcessCopyJobStatusEventRule.name
  target_id = "ProcessAWSBackupCopy-${var.vault_intermediate_name}"
  arn       = aws_lambda_function.BackupCopyManagerLambda.arn
}