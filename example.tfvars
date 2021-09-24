ibmcloud_api_key=""
TF_VERSION="1.0"
prefix="gcat-vsi"
region="us-south"
resource_group="asset-development"
vpc_name=""
subnet_names=[]
image="ibm-ubuntu-18-04-1-minimal-amd64-1"
ssh_public_key=null
existing_ssh_key_name=null
machine_type="bx2-2x8"
vsi_per_subnet=2
user_data_file_path="/config/ubuntu_install_nginx.sh"
enable_floating_ip=true
volumes=[]
security_group_rules=[ { name = "allow-all-outbound" direction = "outbound" remote = "0.0.0.0/0" }, { name = "allow-all-inbound" direction = "inbound" remote = "0.0.0.0/0" } ]
use_public_load_balancer=true
pool={ algorithm = "round_robin" protocol = "http" health_delay = 15 health_retries = 10 health_timeout = 10 health_type = "http" pool_member_port = 80 }
listener={ port = 80 protocol = "http" }
lb_security_group_rules=[ { name = "allow-inbound-port-80" direction = "inbound" remote = "0.0.0.0/0" tcp = { port_min = 80 port_max = 80 } }, { name = "allow-all-outbound" direction = "outbound" remote = "0.0.0.0/0" } ]
