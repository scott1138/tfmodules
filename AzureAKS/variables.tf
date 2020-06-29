variable "resource_group_name" {
    type = string
    description = "Name of the resource group for the Azure Kubernetes Service resource."
}

variable "vnet_resource_group_name" {
    type = string
    description = "Name of the resource group in which the virtual network resides."
}

variable "location"{
    type = string
    description = "Azure region where the resources will be located."
}

variable "cluster_name" {
    type = string
    description = "This is a short name the represents the use of the cluster. Examples: T1-Prod, NonProd2, Sandbox1"
}

variable "node_size" {
    type = string
    description = "Azure VM size for the default node pool"
}

variable "node_count" {
    type = number
    description = "The number of nodes in the default node pool"
}

variable "kubernetes_version" {
    type = string
    description = <<DESC
    The version of Kubernetes to use for the masters and default node pool.
    NOTE: Changing this does not upgrade the node pool, only the masters.
    DESC
}

variable "include_log_analytics" {
    type = bool
    default = false
    description = "Set value to true to create a log analytics workspace for the container logs and kubernetes insights."
}

variable "log_analytics_name" {
    type = string
    default = ""
    description = "Name of an existing log analytics workspace."
}

variable "log_analytics_resource_group" {
    type = string
    default = ""
    description = "Resource group of an existing log analytics workspace."
}

variable "is_hightrust" {
    type = bool
    default = false
    description = <<DESC
    Set to true if the network zone is high trust.
    Currently this sets the following values when false:
        Log Analytics retention to 30 days

    Currently this sets the following values when true:
        Log Analytics retention to 365 days
    DESC
}

variable "udr_required" {
    type = bool
    default = false
    description = <<DESC
    Set to true if user defined routing is required to reach a VNA
    Currently this sets the following when false:
        Use the kubenet network plugin
        Set the pod CIDR to 10.253.32.0/19
        Set max pods per node to 150

    Currently this sets the following when true:
        Use the Azure CNI network plugin
        Does NOT set a pod CIDR
        Set max pods per node to 50
    DESC
}


variable "tags" {
    type = map(string)
    description = "Tags"
}