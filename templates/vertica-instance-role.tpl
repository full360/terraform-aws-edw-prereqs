{
	"Version": "2012-10-17",
	"Statement": [{
			"Sid": "autoscalingdescribe",
			"Effect": "Allow",
			"Action": [
				"autoscaling:Describe*"
			],
			"Resource": "*",
			"Condition": {
				"ForAllValues:StringEquals": {
					"aws:ResourceTag/common_identifier": "${standard_resource_name}"
				}
			}
		},
		{
			"Sid": "ec2describe",
			"Effect": "Allow",
			"Action": [
				"ec2:DescribeVpc*",
				"ec2:DescribeVolumes",
				"ec2:DescribeVolumeAttribute",
				"ec2:DescribeTags",
				"ec2:DescribeSubnets",
				"ec2:DescribeSnapshots",
				"ec2:DescribeSnapshotAttribute",
				"ec2:DescribeNetworkInterfaces",
				"ec2:DescribeInstances"
			],
			"Resource": "*",
			"Condition": {
				"ForAllValues:StringEquals": {
					"ec2:ResourceTag/common_identifier": "${standard_resource_name}"
				}
			}
		},
		{
			"Sid": "logging",
			"Effect": "Allow",
			"Action": [
				"logs:DescribeLogStreams",
				"logs:CreateLogGroup",
				"logs:CreateLogStream",
				"logs:PutLogEvents"
			],
			"Resource": "*"
		},
		{
			"Sid": "ssmparams",
			"Effect": "Allow",
			"Action": [
				"ssm:DescribeParameters",
				"ssm:ListAssociations",
				"ssm:ListInstanceAssociations",
				"ssm:PutComplianceItems",
				"ssm:UpdateInstanceAssociationStatus",
				"ssm:UpdateInstanceInformation",
				"ssm:DescribeAssociation",
				"ssm:GetDeployablePatchSnapshotForInstance",
				"ssm:GetDocument",
				"ssm:DescribeDocument",
				"ssm:GetManifest",
				"ssm:GetParameter",
				"ssm:GetParameters",
				"ssm:ListAssociations",
				"ssm:ListInstanceAssociations",
				"ssm:PutInventory",
				"ssm:PutComplianceItems",
				"ssm:PutConfigurePackageResult",
				"ssm:UpdateAssociationStatus",
				"ssm:UpdateInstanceAssociationStatus",
				"ssm:UpdateInstanceInformation",
				"ssmmessages:CreateControlChannel",
				"ssmmessages:CreateDataChannel",
				"ssmmessages:OpenControlChannel",
				"ssmmessages:OpenDataChannel"
			],
			"Resource": "*",
			"Condition": {
				"ForAllValues:StringEquals": {
					"ec2:ResourceTag/common_identifier": "${standard_resource_name}"
				}
			}
		},
		{
			"Sid": "ec2messages",
			"Effect": "Allow",
			"Action": [
				"ec2messages:AcknowledgeMessage",
				"ec2messages:DeleteMessage",
				"ec2messages:FailMessage",
				"ec2messages:GetEndpoint",
				"ec2messages:GetMessages",
				"ec2messages:SendReply"
			],
			"Resource": "*"
		},
		{
			"Sid": "tagging",
			"Effect": "Allow",
			"Action": [
				"tag:Get*",
				"tag:tagResources"
			],
			"Resource": "*",
			"Condition": {
				"ForAllValues:StringLike": {
					"aws:TagKeys": [
						"${prefix}:*",
						"edw:managed",
						"prefix"
					]
				}
			}
		},
		{
			"Sid": "readonlytags",
			"Effect": "Allow",
			"Action": [
				"tag:Get*"
			],
			"Resource": "*"
		},
		{
			"Sid": "iam",
			"Effect": "Allow",
			"Action": [
				"iam:ListSSHPublicKeys",
				"iam:GetSSHPublicKey",
				"iam:GetRole"
			],
			"Resource": [
				"arn:aws:iam::*:policy/edw-*-instance-policy",
				"arn:aws:iam::*:policy/edw-*-instance-policy-ssm",
				"arn:aws:iam::*:policy/edw-*-ssm-service-policy"
			]
		},
		{
			"Sid": "s3",
			"Effect": "Allow",
			"Action": [
				"s3:ListBucket",
				"s3:GetBucketLocation",
				"s3:ListAllMyBuckets"
			],
			"Resource": "*",
			"Condition": {
				"ForAllValues:StringEquals": {
					"ec2:ResourceTag/common_identifier": "${standard_resource_name}"
				}
			}
		},
		{
			"Sid": "s3hooks",
			"Effect": "Allow",
			"Action": [
				"s3:DeleteObject",
				"s3:GetBucketLocation",
				"s3:GetObject",
				"s3:ListBucket",
				"s3:PutObject"
			],
			"Resource": "*",
			"Condition": {
				"ForAllValues:StringEquals": {
					"aws:ResourceTag/common_identifier": "${standard_resource_name}"
				}
			}
		},
		{
			"Sid": "FullAccessToBackupBucketAndEONModeDataBucket",
			"Effect": "Allow",
			"Action": "s3:*Object",
			"Resource": [
				"arn:aws:s3:::${backup_s3_location}/*",
				"arn:aws:s3:::${eon_s3_location}/*"
			]
		},
		{
			"Sid": "ProvideReadAccessToAllTheSSMParameters",
			"Effect": "Allow",
			"Action": "ssm:GetPar*",
			"Resource": "arn:aws:ssm:*:${account_number}:parameter/${standard_resource_name}*"
		},
		{
			"Sid": "AccessToEncryptAndDeccryptKMSKeys",
			"Effect": "Allow",
			"Action": [
				"kms:Decrypt",
				"kms:ListKeyPolicies",
				"kms:ListRetirableGrants",
				"kms:GetKeyPolicy",
				"kms:ListKeys",
				"kms:ListAliases",
				"kms:ListResourceTags",
				"kms:ListGrants",
				"kms:Encrypt",
				"kms:GetKeyRotationStatus",
				"kms:GenerateDataKey",
				"kms:ReEncryptTo",
				"kms:DescribeKey"
			],
			"Resource": "arn:aws:kms:*:*:key/${vertica_kms_key_id}*"
		},
		{
			"Sid": "AssumeRoleAcrossAccountsForAdditionalCodeExecutionAndLogging",
			"Effect": "Allow",
			"Action": "sts:AssumeRole",
			"Resource": [
				"${remote_logger}"
			]
		},
		{
			"Sid": "MonitorMetricsAndAlarm",
			"Effect": "Allow",
			"Action": "cloudwatch:PutMetricData",
			"Resource": "*"
		},
		{
			"Sid": "ProvideAccessToPublishMessagesToSNS",
			"Effect": "Allow",
			"Action": "sns:Publish",
			"Resource": "${sns_topic_arn}"
		},
		{
			"Sid": "TaggingAndStoppingInstances",
			"Effect": "Allow",
			"Action": [
				"ec2:CopySnapshot",
				"ec2:DeleteSnapshot",
				"ec2:ModifySnapshotAttribute",
				"ec2:DeleteTags",
				"ec2:CreateTags",
				"ec2:CreateSnapshot",
				"ec2:StopInstances"
			],
			"Resource": "*",
			"Condition": {
				"ForAllValues:StringEquals": {
					"ec2:ResourceTag/common_identifier": "${standard_resource_name}"
				}
			}
		},
		{
			"Sid": "AutoScalingGroupPerformLifeCycleEvents",
			"Effect": "Allow",
			"Action": [
				"autoscaling:CompleteLifecycleAction",
				"autoscaling:RecordLifecycleActionHeartbeat",
				"autoscaling:SetInstanceProtection",
				"autoscaling:SetInstanceHealth",
				"cloudformation:SignalResource"
			],
			"Resource": "*",
			"Condition": {
				"ForAllValues:StringEquals": {
					"aws:ResourceTag/common_identifier": "${standard_resource_name}"
				}
			}
		},
		{
			"Sid": "SSMPolicy",
			"Effect": "Allow",
			"Action": [
				"ssm:DescribeAssociation",
				"ssm:GetDocument",
				"ssm:DescribeDocument",
				"ssm:UpdateAssociationStatus",
				"ssm:SendCommand"
			],
			"Resource": "${ssm_document_arn}"
		},
		{
			"Action": "ssm:SendCommand",
			"Effect": "Allow",
			"Resource": [
				"arn:aws:ec2:*:${account_number}:instance/*"
			],
			"Condition": {
				"StringEquals": {
					"ec2:ResourceTag/${prefix}:cluster:common-identifier": [
						"${standard_resource_name}"
					]
				}
			}
		}
	]
}