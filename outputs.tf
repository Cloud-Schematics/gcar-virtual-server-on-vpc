##############################################################################
# VSI Outputs
##############################################################################

output vsi_ids {
  description = "The IDs of the VSI"
  value       = module.virtual_servers.ids
}

output vsi_by_subnet {
  description = "A list of virtual servers by subnet"
  value       = module.virtual_servers.vsi_by_subnet
}

output vsi_list {
    description = "A list of VSI with name, id, zone, and primary ipv4 address"
    value       = module.virtual_servers.list
}

##############################################################################