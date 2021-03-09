output "kms_id" {
  description = "kms id"
  value       = aws_kms_key.vertica_kms_key.id
}

output "kms_arn" {
  description = "kms arn"
  value       = aws_kms_key.vertica_kms_key.arn
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

output "instance_role_name" {
  description = "instance profile"
  value       = aws_iam_instance_profile.vertica_instance_profile
}

output "instance_role_arn" {
  description = "instance role"
  value       = aws_iam_role.vertica_instance_role
}

output "security_group_id" {
  description = "The ID of the security group asg"
  value       = module.asg_sg.this_security_group_id
}

output "cloudformation_stack_name" {
  description = "CF stack name"
  value       = aws_cloudformation_stack.edw_access.name
}