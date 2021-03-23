locals {
  resource_prefix    = "${var.prefix}-${var.environment}"
  backup_bucket_name = "${local.resource_prefix}-backup-data"
  eon_bucket_name    = "${local.resource_prefix}-eon-data"
  sg_name            = "${local.resource_prefix}-sg"
  kms_description    = "${local.resource_prefix}-kms-key"
}

provider "aws" {
  version = "~> 3"
  region  = var.region
}

data "aws_caller_identity" "current" {
}


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
  version = "v1.17.0"

  bucket        = local.backup_bucket_name
  acl           = "log-delivery-write"
  tags          = var.tags
  attach_policy = true

  # Protect the data vendor bucket from being erased if there's content in the
  # bucket.
  force_destroy = false

  # Block public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

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
        days = 180
      }
    },
  ]
}

module "eon_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "v1.17.0"

  bucket        = local.eon_bucket_name
  acl           = "log-delivery-write"
  tags          = var.tags
  attach_policy = true

  # Protect the data vendor bucket from being erased if there's content in the
  # bucket.
  force_destroy = false

  # Block public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  policy = data.aws_iam_policy_document.secure_access_eon.json
}


module "asg_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 3.6"

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
  description             = local.kms_description
  deletion_window_in_days = 7
  tags                    = var.tags
}


data "template_file" "vertica_instance_role_tpl" {
  template = file("${path.module}/templates/vertica-instance-role.tpl")

  vars = {
    account_number                 = data.aws_caller_identity.current.account_id
    edw_principal_account_number   = var.edw_principal_account_number
    standard_resource_name         = "${local.resource_prefix}-*"
    prefix                         = var.prefix
    additional_remote_role_arn     = aws_iam_role.vertica_instance_role.arn
    vertica_kms_key_id             = aws_kms_key.vertica_kms_key.id
    vertica_kms_alias              = ""
    backup_s3_location             = local.backup_bucket_name
    sns_topic_arn                  = var.sns_topic_arn
    cw_system_log_remote_role_arn  = aws_iam_role.vertica_instance_role.arn
    cw_vertica_log_remote_role_arn = aws_iam_role.vertica_instance_role.arn
    eon_s3_location                = local.eon_bucket_name
    ssm_document_arn               = "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:document/${var.prefix}-*"
  }
}


# Attaching the policy File to the Role
#=======================================#
resource "aws_iam_policy" "vertica_instance_policy" {
  name   = "${local.resource_prefix}-instance-policy"
  policy = data.template_file.vertica_instance_role_tpl.rendered
}


# Create Instance role
#==========================#
resource "aws_iam_role" "vertica_instance_role" {
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
  name       = "${local.resource_prefix}-instance-role-policy-attach"
  roles      = [aws_iam_role.vertica_instance_role.name]
  policy_arn = aws_iam_policy.vertica_instance_policy.arn
}


# Create a Instance Profile with the above Created role
#========================================================#
resource "aws_iam_instance_profile" "vertica_instance_profile" {
  name_prefix = local.resource_prefix
  role        = aws_iam_role.vertica_instance_role.name
}


# Create edw access role
# ======================

resource "aws_cloudformation_stack" "edw_access" {
  name = "edw-access-${var.client_id}"

  capabilities = ["CAPABILITY_NAMED_IAM", "CAPABILITY_IAM"]

  parameters = {
    ClientId              = var.client_id
    EDWPrincipalAWSAcctId = var.client_id
    InstanceProfileName   = aws_iam_instance_profile.vertica_instance_profile.arn
    BackupBucket          = module.backup_bucket.this_s3_bucket_arn
    EonBucket             = module.eon_bucket.this_s3_bucket_arn
    InstanceRole          = aws_iam_role.vertica_instance_role.arn
    KmsKey                = aws_kms_key.vertica_kms_key.arn
    EDWPrefix             = local.resource_prefix
    TagPrefix             = var.prefix
    SecurityGroup         = module.asg_sg.this_security_group_id
  }

  template_body = file("${path.module}/templates/role_template.yml")
}
