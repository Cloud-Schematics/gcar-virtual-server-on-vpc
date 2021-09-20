##############################################################################
# Account Variables
##############################################################################

variable resource_group_id {
  description = "ID of resource group to create Virtual Servers"
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

##############################################################################


##############################################################################
# VPC Variables
##############################################################################

variable vpc_id {
    description = "Name of VPC"
    type        = string
}

variable subnets {
    description = "A list of subnet names and zones where Virtual Servers will be created"
    type        = list(
        object(
            {
                id   = string
                name = string
                zone = string
            }
        )
    )
}

##############################################################################


##############################################################################
# Compute Variables
##############################################################################

variable image {
    description = "Image name used for VSI. Run 'ibmcloud is images' to find available images in a region"
    type        = string
    default     = "ibm-ubuntu-18-04-1-minimal-amd64-1"
}

variable ssh_key_id {
    description = "SSH Public key ID to use for compute resources"
    type        = string
}

variable machine_type {
    description = "VSI machine type. Run 'ibmcloud is instance-profiles' to get a list of regional profiles"
    type        =  string
    default     = "bx2-2x8"
}

variable vsi_per_subnet {
    description = "Number of VSI instances for each subnet"
    type        = number
    default     = 1
}

variable user_data {
    description = "Post provision script"
    type        = string
    default     = null
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
            capacity       = number
        })
    )
    default    = [
        
    ]
}

##############################################################################


##############################################################################
# Security Group Rules
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
      name      = "allow-inbound-ping"
      direction = "inbound"
      remote    = "0.0.0.0/0"
      icmp      = {
        type = 8
      }
    },
    {
      name      = "allow-inbound-ssh"
      direction = "inbound"
      remote    = "0.0.0.0/0"
      tcp       = {
        port_min = 22
        port_max = 22
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
