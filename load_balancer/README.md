# Load Balancer Module

This module creates a Load Balancer across any number of subnets, a Load Balancer Pool, adds any number Virtual Serves from those subnets to the back end pool, and then creates a Load Balancer Listener.

## Module Variables

Name                 | Type                                                                                                                                                                                                                                                                                                                             | Description                                                                    | Sensitive | Default
-------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ | --------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
resource_group_id    | string                                                                                                                                                                                                                                                                                                                           | ID of resource group to create resources                                       |           | 
prefix               | string                                                                                                                                                                                                                                                                                                                           | A unique identifier need to provision resources. Must begin with a letter      |           | gcat-vsi
vpc_id               | string                                                                                                                                                                                                                                                                                                                           | ID of VPC                                                                      |           | 
load_balancer        | object({ subnet_ids = list(string) public = bool logging = optional(string) tags = optional(list(string)) })                                                                                                                                                                                                                     | Load balancer to be created                                                    |           | 
pool                 | object({ algorithm = string protocol = string health_delay = number health_retries = number health_timeout = number health_type = string pool_member_port = number health_monitor_url = optional(string) health_monitor_port = optional(number) proxy_protocol = optional(string) session_persistence_type = optional(string) }) | Load balancer pool to be created                                               |           | {<br>algorithm = "round_robin"<br>protocol = "http"<br>health_delay = 15<br>health_retries = 10<br>health_timeout = 10<br>pool_member_port = 80<br>health_type = "http"<br>}
pool_members         | list( object({ name = string id = string zone = string ipv4_address = string floating_ip = optional(string) }) )                                                                                                                                                                                                                 | A list of VSI IDs that will be connected in a load balancer pool               |           | 
listener             | object({ port = number protocol = string certificate_instance = optional(string) certificate_instance = optional(string) accept_proxy_protocol = optional(bool) connection_limit = optional(number) })                                                                                                                           | Load balancer listener                                                         |           | {<br>port = 80<br>protocol = "http"<br>}
security_group_rules | list( object({ name = string direction = string remote = string tcp = optional( object({ port_max = optional(number) port_min = optional(number) }) ) udp = optional( object({ port_max = optional(number) port_min = optional(number) }) ) icmp = optional( object({ type = optional(number) code = optional(number) }) ) }) )  | A list of security group rules to be added to the Load Balancer security group |           | [<br>{<br>name = "allow-all-inbound"<br>direction = "inbound"<br>remote = "0.0.0.0/0"<br>},<br>{<br>name = "allow-all-outbound"<br>direction = "outbound"<br>remote = "0.0.0.0/0"<br>}<br>]

## Module Outputs

Name     | Description                            | Value
-------- | -------------------------------------- | ---------------------
hostname | Hostname for the Load Balancer created | ibm_is_lb.lb.hostname

## Example Module Declaration

```terraform
module load_balancer {
  source               = "./load_balancer"
  resource_group_id    = var.resource_group_id
  prefix               = var.prefix
  vpc_id               = var.vpc_id
  load_balancer        = var.load_balancer
  pool                 = var.pool
  pool_members         = var.pool_members
  listener             = var.listener
  security_group_rules = var.security_group_rules
}
```