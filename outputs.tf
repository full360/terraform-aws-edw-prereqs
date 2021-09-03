output "kms_id" {
  description = "kms id"
  value       = concat(aws_kms_key.vertica_kms_key.*.id, [""])[0]
}

output "kms_arn" {
  description = "kms arn"
  value       = concat(aws_kms_key.vertica_kms_key.*.arn, [""])[0]
}


output "backup_bucket_arn" {
  description = "backup bucket arn"
  value       = module.backup_bucket.this_s3_bucket_arn
}

output "backup_bucket_id" {
  description = "backup bucket id"
  value       = module.backup_bucket.this_s3_bucket_id
}

output "eon_bucket_id" {
  description = "eon bucket id"
  value       = module.eon_bucket.this_s3_bucket_id
}

output "eon_bucket_arn" {
  description = "eon bucket arn"
  value       = module.eon_bucket.this_s3_bucket_arn
}

output "instance_profile_arn" {
  description = "instance profile arn"
  value       = concat(aws_iam_instance_profile.vertica_instance_profile.*.arn, [""])[0]
}

output "instance_profile_name" {
  description = "instance profile name"
  value       = concat(aws_iam_instance_profile.vertica_instance_profile.*.name, [""])[0]
}

output "instance_role_arn" {
  description = "instance role arn"
  value       = concat(aws_iam_role.vertica_instance_role.*.arn, [""])[0]
}

output "instance_role_name" {
  description = "instance role name"
  value       = concat(aws_iam_role.vertica_instance_role.*.name, [""])[0]
}

output "security_group_id" {
  description = "The ID of the security group asg"
  value       = module.asg_sg.this_security_group_id
}

output "cloudformation_stack_name" {
  description = "CF stack name"
  value       = concat(aws_cloudformation_stack.edw_access.*.name, [""])[0]
}

output "cloudformation_fm_stack_name" {
  description = "CF stack name"
  value       = concat(aws_cloudformation_stack.edw_fm_access.*.name, [""])[0]
}

output "role_arn" {
  value = aws_cloudformation_stack.edw_access.outputs.EdwRoleARN
}
