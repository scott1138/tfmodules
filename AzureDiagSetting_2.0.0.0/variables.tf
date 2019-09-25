variable "log_analytics_workspace_id" {
    description = "(Required)Log analytics workspace id"
    type = string
}

variable "resource_id" {
    description = "(Required)Azure resource id of the resource to be configured"
    type = list(string)
}