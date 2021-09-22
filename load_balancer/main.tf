##############################################################################
# Create Load Balancer or Get Load Balancer from Data
##############################################################################

resource ibm_is_lb lb {
  name            = "${var.prefix}-load-balancer"
  subnets         = var.load_balancer.subnet_ids
  type            = var.load_balancer.public ? "public" : "private"
  security_groups = [ ibm_is_security_group.lb_security_group.id ]
  logging         = var.load_balancer.logging
  resource_group  = var.resource_group_id
  tags            = var.load_balancer.tags
}

##############################################################################


##############################################################################
# Load Balancer Pool
##############################################################################

resource ibm_is_lb_pool lb_pool {
  lb                       = ibm_is_lb.lb.id
  name                     = "${var.prefix}-pool"
  algorithm                = var.pool.algorithm                      
  protocol                 = var.pool.protocol   
  proxy_protocol           = var.pool.proxy_protocol        
  health_delay             = var.pool.health_delay       
  health_retries           = var.pool.health_retries     
  health_timeout           = var.pool.health_timeout     
  health_type              = var.pool.health_type        
  health_monitor_url       = var.pool.health_monitor_url 
  health_monitor_port      = var.pool.health_monitor_port
  session_persistence_type = var.pool.session_persistence_type
}

##############################################################################


##############################################################################
# Load Balancer Pool Member
##############################################################################

resource ibm_is_lb_pool_member lb_pool_members {
  count          = length(var.pool_members)
  lb             = ibm_is_lb.lb.id
  pool           = element(split("/", ibm_is_lb_pool.lb_pool.id), 1)
  port           = var.pool.pool_member_port
  target_address = var.pool_members[count.index].ipv4_address
}

##############################################################################


##############################################################################
# Load Balancer Listener
##############################################################################

resource ibm_is_lb_listener lb_listener {
  lb                    = ibm_is_lb.lb.id
  port                  = var.listener.port
  protocol              = var.listener.protocol
  default_pool          = element(split("/", ibm_is_lb_pool.lb_pool.id), 1)
  certificate_instance  = var.listener.certificate_instance 
  connection_limit      = var.listener.connection_limit     
  accept_proxy_protocol = var.listener.accept_proxy_protocol

  depends_on            = [ ibm_is_lb_pool_member.lb_pool_members ]
}

##############################################################################