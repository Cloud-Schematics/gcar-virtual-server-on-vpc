##############################################################################
# Account Variables
# Copyright 2020 IBM
##############################################################################

# Uncomment this variable if running locally
variable ibmcloud_api_key {
  description = "The IBM Cloud platform API key needed to deploy IAM enabled resources"
  type        = string
  sensitive   = true
}

# Comment out if not running in schematics
variable TF_VERSION {
 default     = "1.0"
 type        = string
 description = "The version of the Terraform engine that's used in the Schematics workspace."
}

variable prefix {
    description = "A unique identifier need to provision resources. Must begin with a letter"
    type        = string
    default     = "gcat-vsi"

    validation  {
      error_message = "Unique ID must begin and end with a letter and contain only letters, numbers, and - characters."
      condition     = can(regex("^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$", var.prefix))
    }
}

variable region {
  description = "Region where VPC will be created"
  type        = string
  default     = "us-south"
}

variable resource_group {
    description = "Name of resource group where all infrastructure will be provisioned"
    type        = string
    default     = "asset-development"

    validation  {
      error_message = "Unique ID must begin and end with a letter and contain only letters, numbers, and - characters."
      condition     = can(regex("^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$", var.resource_group))
    }
}

##############################################################################


##############################################################################
# VPC Variables
##############################################################################

variable vpc_name {
    description = "The name of the VPC where VSI will be provisioned"
    type        = string
}

variable subnet_names {
    description = "The name of subnets on the VPC where the virtual servers will be created"
    type        = list(string)
}

##############################################################################


##############################################################################
# VSI Variables
##############################################################################

variable image {
  description = "Image name used for VSI. Run 'ibmcloud is images' to find available images in a region"
  type        = string
  default     = "ibm-ubuntu-18-04-1-minimal-amd64-1"
}

variable ssh_public_key {
  description = "SSH Public Key to create when creating virtual server instances. Using this value will override `existing_ssh_key_name`."
  type        = string
  default     = null
  sensitive   = true
}

variable existing_ssh_key_name {
  description = "Import an existing SSH key by name. Using `ssh_public_key` will override this value"
  type        = string
  default     = null
}

variable machine_type {
  description = "VSI machine type. Run 'ibmcloud is instance-profiles' to get a list of regional profiles"
  type        =  string
  default     = "bx2-2x8"
}

variable vsi_per_subnet {
  description = "Number of VSI instances for each subnet"
  type        = number
  default     = 2
}

variable user_data_file_path {
  description = "Path to a post provision script for virtual servers. Change to `null` to not use a post provision script"
  type        = string
  default     = "/config/ubuntu_install_nginx.sh"
}

variable enable_floating_ip {
  description = "Create a floating IP for each virtual server created"
  type        = bool
  default     = true
}

##############################################################################


##############################################################################
# Volume Variables
##############################################################################

variable volumes {
    description = "A list of volumes to be added to each virtual server instance"
    type        = list(
        object({
            name           = string
            profile        = string
            capacity       = optional(number)
        })
    )
    default    = [
        {
            name     = "one"
            profile  = "10iops-tier"
            capacity = 25
        },
        {
            name    = "two"
            profile = "10iops-tier"
        }
    ]
}

##############################################################################



##############################################################################
# VSI Security Group Rules
##############################################################################

variable security_group_rules {
  description = "A list of security group rules to be added to the VSI security group"
  type        = list(
    object({
      name        = string
      direction   = string
      remote      = string
      tcp         = optional(
        object({
          port_max = optional(number)
          port_min = optional(number)
        })
      )
      udp         = optional(
        object({
          port_max = optional(number)
          port_min = optional(number)
        })
      )
      icmp        = optional(
        object({
          type = optional(number)
          code = optional(number)
        })
      )
    })
  )

  default = [
    {
        name      = "allow-all-outbound"
        direction = "outbound"
        remote    = "0.0.0.0/0"
    },
    {
      name      = "allow-all-inbound"
      direction = "inbound"
      remote    = "0.0.0.0/0"
    }
  ]

  validation {
    error_message = "Security group rules can only have one of `icmp`, `udp`, or `tcp`."
    condition     = length(distinct(
      # Get flat list of results
      flatten([
        # Check through rules
        for rule in var.security_group_rules:
        # Return true if there is more than one of `icmp`, `udp`, or `tcp`
        true if length(
          [
            for type in ["tcp", "udp", "icmp"]:
            true if rule[type] != null
          ]
        ) > 1
      ])
    )) == 0 # Checks for length. If all fields all correct, array will be empty
  }  

  validation {
    error_message = "Security group rule direction can only be `inbound` or `outbound`."
    condition     = length(distinct(
      flatten([
        # Check through rules
        for rule in var.security_group_rules:
        # Return false if direction is not valid
        false if !contains(["inbound", "outbound"], rule.direction)
      ])
    )) == 0
  }

  validation {
    error_message = "Security group rule names must match the regex pattern ^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$."
    condition     = length(distinct(
      flatten([
        # Check through rules
        for rule in var.security_group_rules:
        # Return false if direction is not valid
        false if !can(regex("^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$", rule.name))
      ])
    )) == 0
  }
}

##############################################################################


##############################################################################
# Load Balancer Variables
##############################################################################

variable use_public_load_balancer {
  description = "Use public load balancer. If false, a private one will be created"
  type        = bool
  default     = true
}

##############################################################################


##############################################################################
# Required Pool Variables
##############################################################################

variable pool {
    description = "Load balancer pool to be created"
    type        = object({
        algorithm                = string
        protocol                 = string
        pool_member_port         = number
        health_delay             = number
        health_retries           = number
        health_timeout           = number
        health_type              = string
    })

    default = {
        algorithm        = "round_robin"
        protocol         = "http"
        health_delay     = 15
        health_retries   = 10
        health_timeout   = 10
        health_type      = "http"
        pool_member_port = 80
    }
      
    validation {
        error_message = "Load Balancer Pool algorithm can only be `round_robin`, `weighted_round_robin`, or `least_connections`."
        condition     = var.pool.algorithm == "round_robin" || var.pool.algorithm == "weighted_round_robin" || var.pool.algorithm == "least_connections"
    }

    validation {
        error_message = "Load Balancer Pool Protocol can only be `http`, `https`, or `tcp`."
        condition     = var.pool.protocol == "http" || var.pool.protocol == "https" || var.pool.protocol == "tcp"
    }

    validation {
        error_message = "Pool health delay must be greater than the timeout."
        condition     = var.pool.health_delay > var.pool.health_timeout
    }

    validation {
        error_message = "Load Balancer Pool Health Check Type can only be `http`, `https`, or `tcp`."
        condition     = var.pool.health_type == "http" || var.pool.health_type == "https" || var.pool.health_type == "tcp"
    }
}
##############################################################################


##############################################################################
# Requited Load Balancer Listener Variables
##############################################################################

variable listener {
    description = "Load balancer listener"
    type        = object({
        port     = number
        protocol = string
    })

    default = {
      port     = 80
      protocol = "http"
    }

    validation {
        error_message = "Load Balancer Listener Protocol can only be `http`, `https`, or `tcp`."
        condition     = var.listener.protocol == "http" || var.listener.protocol == "https" || var.listener.protocol == "tcp"
    }
}

##############################################################################

##############################################################################
# Load Balancer Security Group Rules
##############################################################################

variable lb_security_group_rules {
  description = "A list of security group rules to be added to the Load Balancer security group"
  type        = list(
    object({
      name        = string
      direction   = string
      remote      = string
      tcp         = optional(
        object({
          port_max = optional(number)
          port_min = optional(number)
        })
      )
      udp         = optional(
        object({
          port_max = optional(number)
          port_min = optional(number)
        })
      )
      icmp        = optional(
        object({
          type = optional(number)
          code = optional(number)
        })
      )
    })
  )

  default = [
    {
      name      = "allow-inbound-port-80"
      direction = "inbound"
      remote    = "0.0.0.0/0"
      tcp       = {
        port_min = 80
        port_max = 80
      }
    },
    {
      name      = "allow-all-outbound"
      direction = "outbound"
      remote    = "0.0.0.0/0"
    }
  ]

  validation {
    error_message = "Security group rules can only have one of `icmp`, `udp`, or `tcp`."
    condition     = length(distinct(
      # Get flat list of results
      flatten([
        # Check through rules
        for rule in var.lb_security_group_rules:
        # Return true if there is more than one of `icmp`, `udp`, or `tcp`
        true if length(
          [
            for type in ["tcp", "udp", "icmp"]:
            true if rule[type] != null
          ]
        ) > 1
      ])
    )) == 0 # Checks for length. If all fields all correct, array will be empty
  }  

  validation {
    error_message = "Security group rule direction can only be `inbound` or `outbound`."
    condition     = length(distinct(
      flatten([
        # Check through rules
        for rule in var.lb_security_group_rules:
        # Return false if direction is not valid
        false if !contains(["inbound", "outbound"], rule.direction)
      ])
    )) == 0
  }

  validation {
    error_message = "Security group rule names must match the regex pattern ^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$."
    condition     = length(distinct(
      flatten([
        # Check through rules
        for rule in var.lb_security_group_rules:
        # Return false if direction is not valid
        false if !can(regex("^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$", rule.name))
      ])
    )) == 0
  }
}

##############################################################################
