##############################################################################
# VSI Outputs
##############################################################################

output ids {
  description = "The IDs of the VSI"
  value       = [
    for virtual_server in ibm_is_instance.vsi:
    virtual_server.id
  ]
}

output vsi_by_subnet {
  description = "A list of virtual servers by subnet"
  value       = {
    for subnet_name in distinct(local.vsi_list.*.subnet_name):
    subnet_name => [
        for virtual_server in local.vsi_list:
        {
            name         = ibm_is_instance.vsi[virtual_server.name].name
            id           = ibm_is_instance.vsi[virtual_server.name].id
            zone         = ibm_is_instance.vsi[virtual_server.name].zone
            ipv4_address = ibm_is_instance.vsi[virtual_server.name].primary_network_interface.0.primary_ipv4_address

        } if virtual_server.subnet_name == subnet_name
    ]
  }
}

output list {
    description = "A list of VSI with name, id, zone, and primary ipv4 address"
    value       = [
        for virtual_server in ibm_is_instance.vsi:
        {
            name         = virtual_server.name
            id           = virtual_server.id
            zone         = virtual_server.zone
            ipv4_address = virtual_server.primary_network_interface.0.primary_ipv4_address
            floating_ip  = var.enable_floating_ip ? ibm_is_floating_ip.vsi_fip[virtual_server.name].address : null
        }
    ]
}

##############################################################################