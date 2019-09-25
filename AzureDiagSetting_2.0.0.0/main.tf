data "azurerm_monitor_diagnostic_categories" "resource" {
  count       = length(var.resource_id)
  resource_id = var.resource_id[count.index]
}

resource "azurerm_monitor_diagnostic_setting" "diagsetting" {
  count                      = length(var.resource_id)
  name                       = "diagsettings"
  target_resource_id         = var.resource_id[count.index]
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "log" {
    for_each = data.azurerm_monitor_diagnostic_categories.resource[count.index].logs
    content {
      category = log.value
      enabled  = true
        
      retention_policy {
        enabled = true
      }
    }
  }
    
dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.resource[count.index].metrics
    content {
      category = metric.value
      enabled  = true
        
      retention_policy {
        enabled = true 
      }
    }
  }
}

