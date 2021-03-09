{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "BasicDescribePolicyWhichDoesNotTakeRestrictionsNeedToPutStar",
      "Effect": "Allow",
      "Action": [
        "autoscaling:Describe*",
        "ec2:DescribeVpc*",
        "ec2:DescribeVolumes",
        "ec2:DescribeVolumeAttribute",
        "ec2:DescribeTags",
        "ec2:DescribeSubnets",
        "ec2:DescribeSnapshots",
        "ec2:DescribeSnapshotAttribute",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DescribeInstances",
        "logs:DescribeLogStreams",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "ssm:DescribeParameters",
        "ssm:ListAssociations",
        "ssm:ListInstanceAssociations",
        "ssm:PutComplianceItems",
        "ssm:UpdateInstanceAssociationStatus",
        "ssm:UpdateInstanceInformation",
        "ec2messages:AcknowledgeMessage",
        "ec2messages:DeleteMessage",
        "ec2messages:FailMessage",
        "ec2messages:GetEndpoint",
        "ec2messages:GetMessages",
        "ec2messages:SendReply",
        "tag:Get*",
        "tag:tagResources",
        "iam:ListSSHPublicKeys",
        "iam:GetSSHPublicKey",
        "iam:GetRole",
        "s3:ListBucket",
        "s3:GetBucketLocation",
        "s3:ListAllMyBuckets",
        "kms:ListKeys",
        "kms:ListAliases"
      ],
      "Resource": "*"
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
          "arn:aws:iam::073631148609:role/edw-dev-kg8d6nq9p84o-remote-logger"
      ]
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
