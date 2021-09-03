# Terraform AWS module to Pre-Create ElasticDW Prerequisites

This module creates pre-requisites needed for ElasticDW needs. This is primarily to allow a more restricted least-privilege IAM role to be created.

The module to use should be provided by Full360. The module will create resources like 

- S3 Bucket for Backups
- S3 Bucket for EON Data
- KMS Key to encrypt data
- Security Group for the nodes in the cluster
- Instance Role for the nodes in the cluster
- IAM Role for EDW

Variables for customization are available. Please check [variables.tf](variables.tf) in this module


## Notes on the policies

* Amazon Message Delivery Service does not support specifying a resource ARN in the Resource element of an IAM policy statement. To allow access to Amazon Message Delivery Service, specify "Resource": "*" in your policy.  (https://docs.aws.amazon.com/service-authorization/latest/reference/list_amazonmessagedeliveryservice.html)

* Cloudwatch logs groups are not resources managed by EDW so they get created as soon as logs are sent to CloudWatch, because of this the log groups do not have tags, and the naming of the groups depends on random ids generated on cluster creation, which makes it dificult to scope the policy. That is why the policy only allows for create and put logs. It does not allow deletion.

## Installation

### Requirements

Review and prepare requirements:

- [Terraform](https://www.terraform.io/) for version please refer [version.tf](https://github.com/full360/terraform-aws-edw-prereqs/blob/master/versions.tf) file for the terraform version
- [AWS CLI](https://aws.amazon.com/cli/)
- [EDW ClientId](https://www.elasticdw.com/documentation/ui/console/)
- Access to target AWS account ID
- Access to EDW resources Terraform Module
- Access to EDW Cloudformation role template

## How to use the module

### Different access levels

#### Fully Managed
EDW creates and manages all resources. This requires a broader access level to the target account. On this scenario, the module only creates the cross account access role with enough permission to manage all other resources

#### Semi Managed
You create and manage some of the resources. This requires a thiner access to the target account. On this scenario the module create as much resources as possible upfront and the cross account access role with permissions to access only said resources 

### Creating Resources for Vertica Cluster on a Fully Managed Account

1. Create a terraform script (main.tf) with the following content:

    ```jsx
    variable "region" {
      description = "AWS region identifier"
    }

    variable "environment" {
      description = "Environment name (e.g.: dev/prod)"
    }

    variable "prefix" {
      description = "Prefix for resources (ej:edw/foo)"
    }

    variable "edw_principal_account_number" {
      description = "edw main account"
    }

    provider "aws" {
      version = "~> 3.0"
      region  = var.region
    }

    module "edw_resources" {
      source                                 = "git@github.com:full360/terraform-aws-edw-prereqs.git"
      environment = var.environment
      prefix = var.prefix
      client_id = var.client_id
      region  = var.region
      tags = {
        "key1" = "value1"
      }
      edw_principal_account_number = var.edw_principal_account_number
      account_configuration = "fully_managed"
    }

    # outputs
    output "workspace" {
      value = terraform.workspace
    }

    output "module_outputs" {
      description = "edw module outputs"
      value       = module.edw_resources
    }
    ```

2. Create a tfvars (qa.tfvars) file like this

    ```jsx
    region = "us-west-2"

    client_id = "123123123123"

    environment = "dev"

    prefix = "vertica"

    client_id = "34A8D475-A10A-4056-B4C1-D5985A110A09"

    edw_principal_account_number = "123456789"
    ```

3. Create the resources applying the terraform script 

    ```jsx
    terraform apply -var-file=qa.tfvars
    ```

4. The script will start creating resources and after a minute or two should generate an output like the following

    ```jsx
    Outputs:

    module_outputs = {
      ...
    }
    workspace = "default"
    ```

5. You can go ahead and create everything you need on EDW without any assistance
6. You also need to check in your accounts CloudFormation for the stack recently created by the module called edw-access-${client_id} for the ARN of the role created in that stack (The reason why this is a CloudFormation stack is to keep it consistent with how the role is maintained across multiple clients, and used)

### Creating Resources for Vertica Cluster on a Semi Managed Account

1. Create a terraform script (main.tf) with the following content:

    ```jsx
    variable "region" {
      description = "AWS region identifier"
    }

    variable "vpc_id" {
      description = "VPC ID int the target account "
    }

    variable "sns_topic_arn" {
      description = "SNS topic for EDW comms (provided by Full360)"
    }

    variable "environment" {
      description = "Environment name (e.g.: dev/prod)"
    }

    variable "prefix" {
      description = "Prefix for resources (ej:edw/foo)"
    }

    variable "remote_logger" {
      description = "edw remote logger"
    }

    variable "edw_principal_account_number" {
      description = "edw main account"
    }

    provider "aws" {
      version = "~> 3.0"
      region  = var.region
    }

    module "edw_resources" {
      source                                 = "https://github.com/full360/terraform-aws-edw-prereqs?ref=master"
      environment = var.environment
      prefix = var.prefix
      region  = var.region
      client_id = var.client_id
      vpc_id = var.vpc_id
      tags = {
        "key1" = "value1"
      }
      sns_topic_arn = var.sns_topic_arn
      remote_logger = var.remote_logger
      edw_principal_account_number = var.edw_principal_account_number
    }

    # outputs
    output "workspace" {
      value = terraform.workspace
    }

    output "vpc_id" {
      description = "VPC id"
      value       = var.vpc_id
    }

    output "module_outputs" {
      description = "edw module outputs"
      value       = module.edw_resources
    }
    ```

2. Create a tfvars (qa.tfvars) file like this

    ```jsx
    region = "us-west-2"

    sns_topic_arn = "arn:aws:sns:us-west-2:123456789:edw_sns"

    vpc_id = "vpc-123456"

    client_id = "123123123123"

    environment = "dev"

    prefix = "vertica"

    client_id = "34A8D475-A10A-4056-B4C1-D5985A110A09"

    remote_logger = "arn:aws:iam::123456789:role/edw-remote-logger"

    edw_principal_account_number = "123456789"
    ```

3. Create the resources applying the terraform script 

    ```jsx
    terraform apply -var-file=qa.tfvars
    ```

4. The script will start creating resources and after a minute or two should generate an output like the following

    ```jsx
    Outputs:

    module_outputs = {
      ...
    }
    vpc_id = ""
    workspace = "default"
    ```

5. Provide Full 360 the outputs so they can configure your environment as semi managed
6. You also need to check in your accounts CloudFormation for the stack recently created by the module called edw-access-${client_id} for the ARN of the role created in that stack (The reason why this is a CloudFormation stack is to keep it consistent with how the role is maintained across multiple clients, and used)

# Docs
## Providers

| Name | Version |
|------|---------|
| aws | ~> 3 |
| template | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| alb\_egress\_cidr\_blocks | List of IPv4 CIDR ranges to use on all egress rules | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| alb\_egress\_rules | List of egress rules to create by name | `list(string)` | `[]` | no |
| alb\_egress\_with\_cidr\_blocks | List of egress rules to create where 'cidr\_blocks' is used | `list(map(string))` | `[]` | no |
| alb\_egress\_with\_self | List of egress rules to create where 'self' is defined | `list(map(string))` | `[]` | no |
| alb\_ingress\_cidr\_blocks | List of IPv4 CIDR ranges to use on all ingress rules | `list(string)` | `[]` | no |
| alb\_ingress\_rules | List of ingress rules to create by name | `list(string)` | `[]` | no |
| alb\_ingress\_with\_cidr\_blocks | List of ingress rules to create where 'cidr\_blocks' is used | `list(map(string))` | `[]` | no |
| alb\_ingress\_with\_self | List of ingress rules to create where 'self' is defined | `list(map(string))` | `[]` | no |
| asg\_egress\_cidr\_blocks | List of IPv4 CIDR ranges to use on all egress rules | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| asg\_egress\_rules | List of egress rules to create by name | `list(string)` | <pre>[<br>  "all-all"<br>]</pre> | no |
| asg\_egress\_with\_cidr\_blocks | List of egress rules to create where 'cidr\_blocks' is used | `list(map(string))` | `[]` | no |
| asg\_egress\_with\_self | List of egress rules to create where 'self' is defined | `list(map(string))` | `[]` | no |
| asg\_ingress\_cidr\_blocks | List of IPv4 CIDR ranges to use on all ingress rules | `list(string)` | `[]` | no |
| asg\_ingress\_rules | List of ingress rules to create by name | `list(string)` | `[]` | no |
| asg\_ingress\_with\_cidr\_blocks | Default security group rules for Vertica | `list(map(any))` | <pre>[<br>  {<br>    "cidr_blocks": "0.0.0.0/0",<br>    "description": "spread ports",<br>    "from_port": 4803,<br>    "protocol": "tcp",<br>    "to_port": 4803<br>  },<br>  {<br>    "cidr_blocks": "0.0.0.0/0",<br>    "description": "dns",<br>    "from_port": 53,<br>    "protocol": "tcp",<br>    "to_port": 53<br>  },<br>  {<br>    "cidr_blocks": "0.0.0.0/0",<br>    "description": "vsql/sql",<br>    "from_port": 5433,<br>    "protocol": "tcp",<br>    "to_port": 5434<br>  },<br>  {<br>    "cidr_blocks": "0.0.0.0/0",<br>    "description": "inter node comms",<br>    "from_port": 14159,<br>    "protocol": "tcp",<br>    "to_port": 14161<br>  },<br>  {<br>    "cidr_blocks": "0.0.0.0/0",<br>    "description": "Vertica Management Console",<br>    "from_port": 5444,<br>    "protocol": "tcp",<br>    "to_port": 5444<br>  },<br>  {<br>    "cidr_blocks": "0.0.0.0/0",<br>    "description": "Vertica Management Console",<br>    "from_port": 5450,<br>    "protocol": "tcp",<br>    "to_port": 5450<br>  },<br>  {<br>    "cidr_blocks": "0.0.0.0/0",<br>    "description": "Spread",<br>    "from_port": 6543,<br>    "protocol": "tcp",<br>    "to_port": 6543<br>  },<br>  {<br>    "cidr_blocks": "0.0.0.0/0",<br>    "description": "rsync",<br>    "from_port": 50000,<br>    "protocol": "tcp",<br>    "to_port": 50000<br>  },<br>  {<br>    "cidr_blocks": "0.0.0.0/0",<br>    "description": "SSH ports",<br>    "from_port": 22,<br>    "protocol": "tcp",<br>    "to_port": 22<br>  },<br>  {<br>    "cidr_blocks": "0.0.0.0/0",<br>    "description": "spread ports",<br>    "from_port": 4803,<br>    "protocol": "udp",<br>    "to_port": 4804<br>  },<br>  {<br>    "cidr_blocks": "0.0.0.0/0",<br>    "description": "inter node comms",<br>    "from_port": 14159,<br>    "protocol": "udp",<br>    "to_port": 14161<br>  }<br>]</pre> | no |
| asg\_ingress\_with\_self | List of ingress rules to create where 'self' is defined | `list(map(string))` | `[]` | no |
| client\_id | EDW access Client ID, available on the ElasticDW UI > Settings | `any` | n/a | yes |
| default\_sg\_ingress\_cidr\_blocks | Default CIDR block for sg ingress rules | `string` | `"0.0.0.0/0"` | no |
| edw\_principal\_account\_number | The ElasticDW principal account number, available on the ElasticDW UI > Settings | `any` | n/a | yes |
| environment | The environment name | `string` | n/a | yes |
| prefix | The prefix | `string` | n/a | yes |
| region | AWS Region where the resources will be created | `any` | n/a | yes |
| remote\_logger | EDWs remote logger | `any` | n/a | yes |
| role\_path | path specified on role creation | `string` | `"/"` | no |
| sns\_topic\_arn | SNS for EDW | `any` | n/a | yes |
| tags | tags to be applied to the resources created | `map(string)` | n/a | yes |
| vpc\_id | VPC ID | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| backup\_bucket\_arn | backup bucket arn |
| backup\_bucket\_id | backup bucket id |
| cloudformation\_stack\_name | CF stack name |
| eon\_bucket\_arn | eon bucket arn |
| eon\_bucket\_id | eon bucket id |
| instance\_role\_arn | instance role |
| instance\_role\_name | instance profile |
| kms\_arn | kms arn |
| kms\_id | kms id |
| security\_group\_id | The ID of the security group asg |

