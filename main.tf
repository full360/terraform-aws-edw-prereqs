locals {
  resource_prefix    = "${var.prefix}-${var.environment}"
  backup_bucket_name = length(var.custom_backup_bucket_name) > 0 ? var.custom_backup_bucket_name : "${local.resource_prefix}-backup-data"
  eon_bucket_name    = length(var.custom_eon_bucket_name) > 0 ? var.custom_eon_bucket_name : "${local.resource_prefix}-eon-data"
  cf_stack_name      = length(var.custom_cf_name) > 0 ? var.custom_cf_name : "edw-access-${local.resource_prefix}-${var.client_id}"
  sg_name            = "${local.resource_prefix}-sg"
  kms_description    = "${local.resource_prefix}-kms-key"

  create_backup_bucket  = var.configuration_maps[var.account_configuration].backup_bucket
  create_eon_bucket     = var.configuration_maps[var.account_configuration].eon_bucket
  create_access_role    = var.configuration_maps[var.account_configuration].access_role
  create_instance_role  = var.configuration_maps[var.account_configuration].instance_role
  create_kms_key        = var.configuration_maps[var.account_configuration].kms_key
  create_security_group = var.configuration_maps[var.account_configuration].security_group
  force_destroy         = var.configuration_maps[var.account_configuration].force_destroy

  create_fm_access_role = local.create_access_role ? var.account_configuration == "fully_managed" ? 1 : 0 : 0
  create_sm_access_role = local.create_access_role ? var.account_configuration == "semi_managed" ? 1 : 0 : 0
}


data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "secure_access_backup" {

  statement {
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:*",
    ]

    resources = [
      "${module.backup_bucket.this_s3_bucket_arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

data "aws_iam_policy_document" "secure_access_eon" {

  statement {
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:*",
    ]

    resources = [
      "${module.eon_bucket.this_s3_bucket_arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}


module "backup_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "v1.9.0"

  create_bucket = local.create_backup_bucket
  bucket        = local.backup_bucket_name
  acl           = "private"
  tags          = var.tags
  attach_policy = true

  # Protect the data vendor bucket from being erased if there's content in the
  # bucket.
  force_destroy = local.force_destroy

  # Block public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm     = var.sse_algorithm
        kms_master_key_id = var.sse_kms_master_key_id
      }
    }
  }

  policy = data.aws_iam_policy_document.secure_access_backup.json

  lifecycle_rule = [
    {
      id                                     = "archive-and-delete-data"
      enabled                                = true
      abort_incomplete_multipart_upload_days = 7

      transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
      ]

      expiration = {
        days = 0
      }
    },
  ]
}

module "eon_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "v1.9.0"

  create_bucket = local.create_eon_bucket
  bucket        = local.eon_bucket_name
  acl           = "private"
  tags          = var.tags
  attach_policy = true

  # Protect the data vendor bucket from being erased if there's content in the
  # bucket.
  force_destroy = local.force_destroy

  # Block public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm     = var.sse_algorithm
        kms_master_key_id = var.sse_kms_master_key_id
      }
    }
  }


  policy = data.aws_iam_policy_document.secure_access_eon.json
}


module "asg_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 3.6"

  create      = local.create_security_group
  name        = local.sg_name
  description = "Security Group for ${local.resource_prefix}"
  tags        = var.tags
  vpc_id      = var.vpc_id

  ingress_rules            = var.asg_ingress_rules
  ingress_with_self        = var.asg_ingress_with_self
  ingress_with_cidr_blocks = var.asg_ingress_with_cidr_blocks
  ingress_cidr_blocks      = var.asg_ingress_cidr_blocks

  egress_rules            = var.asg_egress_rules
  egress_with_self        = var.asg_egress_with_self
  egress_with_cidr_blocks = var.asg_egress_with_cidr_blocks
  egress_cidr_blocks      = var.asg_egress_cidr_blocks
}


resource "aws_kms_key" "vertica_kms_key" {
  count                   = local.create_kms_key ? 1 : 0
  description             = local.kms_description
  deletion_window_in_days = 7
  tags                    = var.tags
}


data "template_file" "vertica_instance_role_tpl" {
  count    = local.create_instance_role ? 1 : 0
  template = file("${path.module}/templates/vertica-instance-role.tpl")

  vars = {
    account_number                 = data.aws_caller_identity.current.account_id
    edw_principal_account_number   = var.edw_principal_account_number
    standard_resource_name         = "${local.resource_prefix}-*"
    prefix                         = var.prefix
    additional_remote_role_arn     = aws_iam_role.vertica_instance_role[0].arn
    vertica_kms_key_id             = aws_kms_key.vertica_kms_key[0].id
    vertica_kms_alias              = ""
    backup_s3_location             = local.backup_bucket_name
    sns_topic_arn                  = var.sns_topic_arn
    cw_system_log_remote_role_arn  = aws_iam_role.vertica_instance_role[0].arn
    cw_vertica_log_remote_role_arn = aws_iam_role.vertica_instance_role[0].arn
    eon_s3_location                = local.eon_bucket_name
    ssm_document_arn               = "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:document/${var.prefix}-*"
    region                         = var.region
    remote_logger                  = var.remote_logger
  }
}


# ======================
# Attaching the policy File to the Role
#=======================================#
resource "aws_iam_policy" "vertica_instance_policy" {
  count  = local.create_instance_role ? 1 : 0
  name   = "${local.resource_prefix}-instance-policy"
  policy = data.template_file.vertica_instance_role_tpl[0].rendered
}


# ======================
# Create Instance role
#==========================#
resource "aws_iam_role" "vertica_instance_role" {
  count       = local.create_instance_role ? 1 : 0
  name        = "${local.resource_prefix}-instance-role"
  path        = var.role_path
  description = "Role to be Assumed by EC2 Instances"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {"Service": "ec2.amazonaws.com"},
      "Effect": "Allow",
      "Sid": ""
    },
    {
      "Action": "sts:AssumeRole",
      "Principal": {"Service": "events.amazonaws.com"},
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF


  tags = var.tags
}

resource "aws_iam_policy_attachment" "vertica_instance_role_policy_attach-1" {
  count      = local.create_instance_role ? 1 : 0
  name       = "${local.resource_prefix}-instance-role-policy-attach"
  roles      = [aws_iam_role.vertica_instance_role[0].name]
  policy_arn = aws_iam_policy.vertica_instance_policy[0].arn
}


# =======================================================#
# Create a Instance Profile with the above Created role
#========================================================#
resource "aws_iam_instance_profile" "vertica_instance_profile" {
  count       = local.create_instance_role ? 1 : 0
  name_prefix = local.resource_prefix
  role        = aws_iam_role.vertica_instance_role[0].name
}


# ======================
# Create edw access role
# ======================
resource "aws_cloudformation_stack" "edw_access" {
  count = local.create_sm_access_role
  name  = local.cf_stack_name

  capabilities = ["CAPABILITY_NAMED_IAM", "CAPABILITY_IAM"]

  parameters = {
    ClientId              = var.client_id
    InstanceProfileName   = aws_iam_instance_profile.vertica_instance_profile[0].arn
    BackupBucket          = module.backup_bucket.this_s3_bucket_arn
    EonBucket             = module.eon_bucket.this_s3_bucket_arn
    InstanceRole          = aws_iam_role.vertica_instance_role[0].arn
    KmsKey                = aws_kms_key.vertica_kms_key[0].arn
    EDWPrefix             = local.resource_prefix
    TagPrefix             = var.prefix
    SecurityGroup         = module.asg_sg.this_security_group_id
    EDWPrincipalAWSAcctId = var.edw_principal_account_number
  }

  template_body = file("${path.module}/templates/sm_role_template.yml")
}

resource "aws_cloudformation_stack" "edw_fm_access" {
  count = local.create_fm_access_role
  name  = "edw-access-${local.resource_prefix}-${var.client_id}"

  capabilities = ["CAPABILITY_NAMED_IAM", "CAPABILITY_IAM"]

  parameters = {
    ClientId              = var.client_id
    EDWPrincipalAWSAcctId = var.edw_principal_account_number
  }

  template_body = file("${path.module}/templates/fm_role_template.yml")
}
