# AKS Node NotReady Alert Setup (Terraform)

This document describes a simple but effective Azure Monitor alerting setup using Terraform to detect when any AKS (Azure Kubernetes Service) node reports a `NotReady` status. This is part of a production-grade monitoring strategy.

---

## 📌 Objective

Detect when any AKS node is in a `NotReady` state in the past 10 minutes and immediately notify the appropriate team via email.

---

## 🧱 Resources Defined

### 1. **Log Analytics Workspace**
```hcl
resource "azurerm_log_analytics_workspace" "demo" {
  name                = "{{var.prefix}}-law"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}
```

Used to collect AKS control plane logs and metrics. Acts as the scope for log query alerts.

---

### 2. **Diagnostic Settings for AKS**
```hcl
resource "azurerm_monitor_diagnostic_setting" "aks" {
  name                       = "{{var.prefix}}-aks-to-law"
  target_resource_id         = var.aks_cluster_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.demo.id

  enabled_log  {
    category = "kube-apiserver"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
```

Sends AKS control-plane logs and metrics to the Log Analytics workspace.

---

### 3. **Alert Rule for Node NotReady**
```hcl
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "aks_nodes_not_ready" {
  name                 = "{{var.prefix}}-aks-nodes-notready"
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

    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 0

    dimension {
      name     = "ClusterName"
      operator = "Include"
      values   = ["*"]
    }

    failing_periods {
      number_of_evaluation_periods = 1
      minimum_failing_periods_to_trigger_alert = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.demo.id]
  }
}
```

---

### 4. **Action Group for Notifications**
```hcl
resource "azurerm_monitor_action_group" "demo" {
  name                = "{{var.prefix}}-ag"
  resource_group_name = var.resource_group_name
  short_name          = "demoAG"

  email_receiver {
    name                    = "demo"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }
}
```

Sends alert notifications to an email address. `use_common_alert_schema` ensures consistency for downstream integrations.

---

## 🔍 KQL Logic Explained

```kql
KubeNodeInventory
| where TimeGenerated > ago(10m)
| summarize arg_max(TimeGenerated, *) by ClusterName, Computer
| where Status !~ "Ready"
| summarize NodesNotReady = count() by ClusterName
```

- Filters last 10 minutes.
- Gets latest node status using `arg_max`.
- Filters nodes that are **not** in `"Ready"` status.
- Counts how many problematic nodes per cluster.

---

## ✅ Alert Characteristics

| Parameter | Value |
|----------|-------|
| Severity | 2 (Critical) |
| Trigger | If any node is NotReady |
| Evaluation Frequency | Every 5 minutes |
| Window | Last 10 minutes |
| Dimension | ClusterName |
| Action | Email via Action Group |

---

## 🚀 Enhancements (Optional)

- Add more log categories like `kube-controller-manager`, `cluster-autoscaler`, `guard`
- Extend action group to integrate with PagerDuty, Slack, Logic Apps, etc.
- Add Prometheus/Grafana alerts for finer granularity

---
