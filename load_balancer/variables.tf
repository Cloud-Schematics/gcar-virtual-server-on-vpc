##############################################################################
# Load Balancer Variables
# Copyright 2020 IBM
##############################################################################

variable resource_group_id {
  description = "ID of resource group to create resources"
  type        = string
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

variable vpc_id {
  description = "ID of VPC"
  type        = string
}

variable load_balancer {
  description = "Load balancer to be created"
  type        = object({
    subnet_ids         = list(string)
    public             = bool
    logging            = optional(string)
    tags               = optional(list(string))
  })
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
        health_delay             = number
        health_retries           = number
        health_timeout           = number
        health_type              = string
        pool_member_port         = number
        health_monitor_url       = optional(string)
        health_monitor_port      = optional(number)
        proxy_protocol           = optional(string)
        session_persistence_type = optional(string)
    })

    default = {
        algorithm        = "round_robin"
        protocol         = "http"
        health_delay     = 15
        health_retries   = 10
        health_timeout   = 10
        pool_member_port = 80
        health_type      = "http"
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
# Load Balancer Pool Member Variables
##############################################################################

variable pool_members {
    description = "A list of VSI IDs that will be connected in a load balancer pool"
    type        = list(
        object({
            name         = string
            id           = string
            zone         = string
            ipv4_address = string
            floating_ip  = optional(string)
        })
    )
}
##############################################################################


##############################################################################
# Requited Load Balancer Listener Variables
##############################################################################

variable listener {
    description = "Load balancer listener"
    type        = object({
        port                  = number
        protocol              = string
        certificate_instance  = optional(string)
        certificate_instance  = optional(string)
        accept_proxy_protocol = optional(bool)
        connection_limit      = optional(number)
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
# Security Group Rules
##############################################################################

variable security_group_rules {
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
        name      = "allow-all-inbound"
        direction = "inbound"
        remote    = "0.0.0.0/0"
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
