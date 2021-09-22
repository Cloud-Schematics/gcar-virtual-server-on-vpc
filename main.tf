##############################################################################
# IBM Cloud Provider
##############################################################################

provider ibm {
  # Uncomment if running locally
  ibmcloud_api_key      = var.ibmcloud_api_key
  region                = var.region
  ibmcloud_timeout      = 60
}

##############################################################################


##############################################################################
# Resource Group where Virtual Servers will be created
##############################################################################

data ibm_resource_group resource_group {
  name = var.resource_group
}

##############################################################################


##############################################################################
# VPC Data
##############################################################################

data ibm_is_vpc vpc {
  name = var.vpc_name
}

data ibm_is_subnet subnet {
  for_each = toset(var.subnet_names)
  name     = each.key
}

##############################################################################


##############################################################################
# Virtual Server Data
##############################################################################

data ibm_is_image image {
    name = var.image
}

##############################################################################


##############################################################################
# Either create or fetch SSH Key
##############################################################################

resource ibm_is_ssh_key created_key {
  count          = var.ssh_public_key == null ? 0 : 1
  name           = "${var.prefix}-ssh-key"
  public_key     = var.ssh_public_key
  resource_group = data.ibm_resource_group.resource_group.id
}

data ibm_is_ssh_key existing_ssh_key {
  count = var.ssh_public_key == null ? 1 : 0
  name  = var.existing_ssh_key_name
}

locals {
  ssh_key_id = (
    var.ssh_public_key == null 
    ? data.ibm_is_ssh_key.existing_ssh_key[0].id 
    : ibm_is_ssh_key.created_key[0].id
  )
}

##############################################################################


##############################################################################
# Create Virtual Servers
##############################################################################\

locals {
  subnets = [
    for subnet in data.ibm_is_subnet.subnet:
    {
      id   = subnet.id
      name = subnet.name
      zone = subnet.zone
    }
  ]
}

module virtual_servers {
  source               = "./virtual_server"
  resource_group_id    = data.ibm_resource_group.resource_group.id
  prefix               = var.prefix
  vpc_id               = data.ibm_is_vpc.vpc.id
  subnets              = local.subnets
  ssh_key_id           = local.ssh_key_id
  vsi_per_subnet       = var.vsi_per_subnet
  security_group_rules = var.security_group_rules
  enable_floating_ip   = var.enable_floating_ip
  machine_type         = var.machine_type
  user_data            = var.user_data_file_path == null ? null : file("${path.module}/${var.user_data_file_path}")
}

module load_balancer {
  source               = "./load_balancer"
  resource_group_id    = data.ibm_resource_group.resource_group.id
  security_group_rules = var.lb_security_group_rules
  vpc_id               = data.ibm_is_vpc.vpc.id
  prefix               = var.prefix
  load_balancer        = {
    public     = var.use_public_load_balancer
    subnet_ids = local.subnets.*.id
  }
  pool                 = var.pool
  listener             = var.listener
  pool_members         = module.virtual_servers.list
}

##############################################################################