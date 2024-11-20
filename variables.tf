variable "tags" {
  type = map(string)
}

variable "source_account_id" {
  description = "Source AWS account"
  type        = string
  default     = "<source_account_id>"
}


# Variables
variable "vault_source_name" {
  description = "Source backup vault name to make initial DB backup and copy from"
  type        = string
  default     = ""
}

variable "vault_intermediate_name" {
  description = "Intermediate backup vault name to copy DB backup within same account (should be in a DR vault region)"
  type        = string
  default     = ""
}

variable "dr_account_id" {
  type    = string
  default = "<DR_account_id>"
}

variable "key_admin_identity" {
  type    = string
  default = "role/<iam_role_name>"
}

variable "vault_intermediate_region" {
  description = "Intermediate backup vault region (same as a DR vault region)"
  type        = string
  default     = ""
}
