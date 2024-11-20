
# IAM Managed Policy
resource "aws_iam_policy" "rIAMManagedPolicy" {
  provider    = aws.aws-source
  name        = "AWSBackupCopyCompleteEventBridgePolicy-${var.vault_intermediate_name}"
  path        = "/service-role/"
  description = "AWS Backup Copy Complete EventBridge Policy"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "events:PutEvents"
      ],
      "Resource": [
        "arn:aws:events:${var.vault_intermediate_region}:${var.source_account_id}:event-bus/default"
      ]
    }
  ]
}
POLICY
}

# IAM Role
resource "aws_iam_role" "rIAMRole" {
  provider           = aws.aws-source
  name               = "BackupCopyComplete-${var.vault_intermediate_name}"
  path               = "/service-role/"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

  max_session_duration = 3600
}

# IAM Policy Attachment
resource "aws_iam_policy_attachment" "rIAMManagedPolicyAttachment" {
  provider   = aws.aws-source
  name       = "AWSBackupCopyCompleteEventBridgePolicyAttachment-${var.vault_intermediate_name}"
  roles      = [aws_iam_role.rIAMRole.name]
  policy_arn = aws_iam_policy.rIAMManagedPolicy.arn
}

# EventBridge Rule
resource "aws_cloudwatch_event_rule" "rEventsRule" {
  provider       = aws.aws-source
  name           = "BackupCopyComplete-${var.vault_intermediate_name}"
  description    = "Event Rule for AWS Backup Copy Job Complete Event, DR backup"
  event_bus_name = "default"
  event_pattern  = <<PATTERN
{
  "source": ["aws.backup"],
  "detail-type": ["Copy Job State Change"],
  "detail": {
    "state": ["COMPLETED"],
    "destinationBackupVaultArn": ["${aws_backup_vault.rBackupVault-intermediate.arn}"]
  }
}
PATTERN

  state = "ENABLED"
}

# CloudWatch Event Target
resource "aws_cloudwatch_event_target" "rEventsRuleTarget" {
  provider  = aws.aws-source
  rule      = aws_cloudwatch_event_rule.rEventsRule.name
  target_id = "Target-${var.vault_intermediate_name}"

  arn      = "arn:aws:events:${var.vault_intermediate_region}:${var.source_account_id}:event-bus/default"
  role_arn = aws_iam_role.rIAMRole.arn
}