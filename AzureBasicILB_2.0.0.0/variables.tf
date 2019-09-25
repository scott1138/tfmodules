variable "location" {
  description = "(Required) The location/region where the core network will be created. The full list of Azure regions can be found at https://azure.microsoft.com/regions"
}

variable "resource_group_name" {
  description = "(Required) The name of the resource group where the load balancer resources will be placed."
}

variable "subnet_name" {
  description = "(Required) Name of the subnet to deploy the load balancer in."
}

variable "vnet_resource_group_name" {
  description = "(Required) Name of the resource group where the Virtual Network resides."
}

variable "vnet_name" {
  description = "(Required) Name of the Virtual Network where the subnet resides."
}

variable "lb_prefix" {
  description = "(Required) Default prefix to use with your load balancer name, should matched the rources behind it. example: PRDAPPWFE"
}

variable "lb_port" {
  description = "Protocols to be used for lb health probes and rules. [frontend_port, protocol, backend_port]"
  default = {
    https = ["443", "tcp", "443"]
  }
}

variable "lb_probe_unhealthy_threshold" {
  description = "Number of times the load balancer health probe has an unsuccessful attempt before considering the endpoint unhealthy."
  default     = 2
}

variable "lb_probe_interval" {
  description = "Interval in seconds the load balancer health probe rule does a check"
  default     = 5
}

variable "frontend_private_ip_address" {
  description = "(Required) Private ip address to assign to frontend. Use it with type = private"
}

variable "load_distribution" {
  description = "(Optional) Specifies the load balancing distribution type to be used by the Load Balancer. Possible values are: Default – The load balancer is configured to use a 5 tuple hash to map traffic to available servers. SourceIP – The load balancer is configured to use a 2 tuple hash to map traffic to available servers. SourceIPProtocol – The load balancer is configured to use a 3 tuple hash to map traffic to available servers. Also known as Session Persistence, where the options are called None, Client IP and Client IP and Protocol respectively."
  default     = "Default"
}

variable "network_interface_id" {
  description = "(Required) The network interface ids to be assigned to this load balancer."
  type = list
}

variable "tags" {
  type = map(string)
}

