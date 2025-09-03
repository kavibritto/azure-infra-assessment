# One simple alert: AKS node NotReady
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "aks_nodes_not_ready" {
  name                 = "${var.prefix}-aks-nodes-notready"
  resource_group_name  = var.resource_group_name
  location             = var.location
  scopes               = [azurerm_log_analytics_workspace.demo.id]
  enabled              = true
  severity             = 2
  evaluation_frequency = "PT5M"
  window_duration      = "PT10M"
  description          = "Alerts if any AKS node is NotReady in the last 10 minutes."

  criteria {
    query = <<-KQL
      KubeNodeInventory
      | where TimeGenerated > ago(10m)
      | summarize arg_max(TimeGenerated, *) by ClusterName, Computer
      | where Status !~ "Ready"
      | summarize NodesNotReady = count() by ClusterName
    KQL

    # How the result is evaluated
    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 0

    # Optional: keep wildcard dimension so rule stays valid if the table includes it
    dimension {
      name     = "ClusterName"
      operator = "Include"
      values   = ["*"]
    }

    # Alert as soon as a single evaluation fails
    failing_periods {
      number_of_evaluation_periods = 1
      minimum_failing_periods_to_trigger_alert = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.demo.id]
  }
}

resource "azurerm_monitor_action_group" "demo" {
  name                = "${var.prefix}-ag"
  resource_group_name = var.resource_group_name
  short_name          = "demoAG"

  email_receiver {
    name                    = "demo"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }
}

# Send AKS control-plane logs & metrics to LAW
resource "azurerm_monitor_diagnostic_setting" "aks" {
  name                       = "${var.prefix}-aks-to-law"
  target_resource_id         = var.aks_cluster_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.demo.id

  enabled_log  {
    category = "kube-apiserver"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
resource "azurerm_log_analytics_workspace" "demo" {
  name                = "${var.prefix}-law"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}
