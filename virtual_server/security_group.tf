##############################################################################
# Update default security group
##############################################################################

locals {
  # Convert to object
  security_group_rule_object = {
    for rule in var.security_group_rules:
    rule.name => rule
  }
}

resource ibm_is_security_group vsi_security_group {
    name           = "${var.prefix}-security-group"
    resource_group = var.resource_group_id
    vpc            = var.vpc_id
}

resource ibm_is_security_group_rule vsi_security_group_rules {
  for_each  = local.security_group_rule_object
  group     = ibm_is_security_group.vsi_security_group.id
  direction = each.value.direction
  remote    = each.value.remote

  dynamic tcp { 
    for_each = each.value.tcp == null ? [] : [each.value]
    content {
      port_min = each.value.tcp.port_min
      port_max = each.value.tcp.port_max
    }
  }

  dynamic udp { 
    for_each = each.value.udp == null ? [] : [each.value]
    content {
      port_min = each.value.udp.port_min
      port_max = each.value.udp.port_max
    }
  } 

  dynamic icmp { 
    for_each = each.value.icmp == null ? [] : [each.value]
    content {
      type = each.value.icmp.type
      code = each.value.icmp.code
    }
  } 
}

##############################################################################
