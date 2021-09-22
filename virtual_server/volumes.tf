##############################################################################
# Create Volumes
##############################################################################

locals {

    # List of volumes for each VSI
    volume_list = flatten([
        # For each subnet
        for subnet in var.subnets: [
            # For each number in a range from 0 to VSI per subnet
            for count in range(var.vsi_per_subnet): [
                # For each volume
                for volume in var.volumes:
                {
                    name     = "${subnet.name}-${var.prefix}-${count + 1}-${volume.name}"
                    zone     = subnet.zone
                    profile  = volume.profile
                    capacity = volume.capacity
                    vsi_name = "${subnet.name}-${var.prefix}-${count + 1}"
                }
            ]
        ]
    ])

    # Map of all volumes
    volume_map = {
        for volume in local.volume_list:
        volume.name => volume
    }
}

##############################################################################


##############################################################################
# Create Volumes
##############################################################################

resource ibm_is_volume volume {
    for_each = local.volume_map
    name     = each.key
    profile  = each.value.profile
    zone     = each.value.zone
    capacity = each.value.capacity
}

##############################################################################


##############################################################################
# Map Volumes to VSI Name
##############################################################################

locals {
    # Create a map that groups lists of volumes by VSI name to be referenced in 
    # instance creation
    volume_by_vsi = {
        # For each distinct server name
        for virtual_server in distinct(local.volume_list.*.vsi_name):
        # Create an object where the key is the name of the server
        (virtual_server) => [
            # That includes the ids of only volumes with the matching `vsi_name`
            for volume in local.volume_list:
            ibm_is_volume.volume[volume.name].id if volume.vsi_name == virtual_server
        ]
    }
}

##############################################################################