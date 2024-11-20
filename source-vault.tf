# AWS KMS Key
resource "aws_kms_key" "rKMSCMK-source" {
  provider            = aws.aws-source
  enable_key_rotation = true
  description         = "KMS multi-region key for Aurora DB Source DR backup Vault"
  multi_region        = true

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "backup-vault-cmk-policy-${var.vault_source_name}",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${var.source_account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "Allow administration of the key",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${var.source_account_id}:${var.key_admin_identity}"
      },
      "Action": [
        "kms:Create*",
        "kms:Describe*",
        "kms:Enable*",
        "kms:List*",
        "kms:Put*",
        "kms:Update*",
        "kms:Revoke*",
        "kms:Disable*",
        "kms:Get*",
        "kms:Delete*",
        "kms:ScheduleKeyDeletion*",
        "kms:CancelKeyDeletion*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "Allow access from Backup account to copy backups",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": [
        "kms:CreateGrant",
        "kms:Decrypt",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "kms:CallerAccount": "${var.dr_account_id}"
        }
      }
    }
  ]
}
POLICY
}

# AWS KMS Alias
resource "aws_kms_alias" "rKMSCMKAlias-source" {
  provider      = aws.aws-source
  name          = "alias/cmk-${var.vault_source_name}"
  target_key_id = aws_kms_key.rKMSCMK-source.key_id
}

# AWS Backup Vault
resource "aws_backup_vault" "rBackupVault" {
  provider    = aws.aws-source
  name        = var.vault_source_name
  kms_key_arn = aws_kms_key.rKMSCMK-source.arn
}