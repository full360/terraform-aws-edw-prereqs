#----------------------------------------------------------------
# Required variables
#----------------------------------------------------------------
variable "environment" {
  description = "The environment name"
  type        = string
}

variable "prefix" {
  description = "The prefix"
  type        = string
}

variable "region" {
  description = "AWS Region where the resources will be created"
}

variable "vpc_id" {
  description = "VPC ID"
}

variable "client_id" {
  description = "EDW access Client ID, available on the ElasticDW UI > Settings"
}

variable "edw_principal_account_number" {
  description = "The ElasticDW principal account number, available on the ElasticDW UI > Settings"
}

variable "sns_topic_arn" {
  description = "SNS for EDW"
}

###SG

variable "alb_ingress_rules" {
  description = "List of ingress rules to create by name"
  type        = list(string)
  default     = []
}

variable "alb_ingress_with_self" {
  description = "List of ingress rules to create where 'self' is defined"
  type        = list(map(string))
  default     = []
}

variable "alb_ingress_with_cidr_blocks" {
  description = "List of ingress rules to create where 'cidr_blocks' is used"
  type        = list(map(string))
  default     = []
}

variable "alb_ingress_cidr_blocks" {
  description = "List of IPv4 CIDR ranges to use on all ingress rules"
  type        = list(string)
  default     = []
}

variable "alb_egress_rules" {
  description = "List of egress rules to create by name"
  type        = list(string)
  default     = []
}

variable "alb_egress_with_self" {
  description = "List of egress rules to create where 'self' is defined"
  type        = list(map(string))
  default     = []
}

variable "alb_egress_with_cidr_blocks" {
  description = "List of egress rules to create where 'cidr_blocks' is used"
  type        = list(map(string))
  default     = []
}

variable "alb_egress_cidr_blocks" {
  description = "List of IPv4 CIDR ranges to use on all egress rules"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# SG ASG
variable "asg_ingress_rules" {
  description = "List of ingress rules to create by name"
  type        = list(string)
  default     = []
}

variable "asg_ingress_with_self" {
  description = "List of ingress rules to create where 'self' is defined"
  type        = list(map(string))
  default     = []
}

variable "asg_ingress_cidr_blocks" {
  description = "List of IPv4 CIDR ranges to use on all ingress rules"
  type        = list(string)
  default     = []
}

variable "asg_egress_rules" {
  description = "List of egress rules to create by name"
  type        = list(string)
  default     = ["all-all"]
}

variable "asg_egress_with_self" {
  description = "List of egress rules to create where 'self' is defined"
  type        = list(map(string))
  default     = []
}

variable "asg_egress_with_cidr_blocks" {
  description = "List of egress rules to create where 'cidr_blocks' is used"
  type        = list(map(string))
  default     = []
}

variable "asg_egress_cidr_blocks" {
  description = "List of IPv4 CIDR ranges to use on all egress rules"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "asg_ingress_with_cidr_blocks" {
  description = "Default security group rules for Vertica"
  type        = list(map(any))
  default = [
    {
      from_port   = 4803
      to_port     = 4803
      protocol    = "tcp"
      description = "spread ports"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 53
      to_port     = 53
      protocol    = "tcp"
      description = "dns"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 5433
      to_port     = 5434
      protocol    = "tcp"
      description = "vsql/sql"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 14159
      to_port     = 14161
      protocol    = "tcp"
      description = "inter node comms"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 5444
      to_port     = 5444
      protocol    = "tcp"
      description = "Vertica Management Console"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 5450
      to_port     = 5450
      protocol    = "tcp"
      description = "Vertica Management Console"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 6543
      to_port     = 6543
      protocol    = "tcp"
      description = "Spread"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 50000
      to_port     = 50000
      protocol    = "tcp"
      description = "rsync"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH ports"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 4803
      to_port     = 4804
      protocol    = "udp"
      description = "spread ports"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 14159
      to_port     = 14161
      protocol    = "udp"
      description = "inter node comms"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

variable "default_sg_ingress_cidr_blocks" {
  description = "Default CIDR block for sg ingress rules"
  default     = "0.0.0.0/0"
}

variable "role_path" {
  description = "path specified on role creation"
  default     = "/"
}

#######################


variable "tags" {
  description = "tags to be applied to the resources created"
  type        = map(string)
}