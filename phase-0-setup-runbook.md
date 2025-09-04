
# Phase 0: Azure & GitHub Setup – Runbook

## 🎯 Objective
Prepare an Azure sandbox environment with GitHub Actions CI/CD by:
- Creating a federated Service Principal
- Linking GitHub repo via OIDC (no secrets)
- Validating Azure CLI and GitHub authentication

---

## ✅ Prerequisites

- Azure Free Trial subscription
- GitHub repository ready
- Azure CLI installed and authenticated

---

## 🔧 Step-by-Step Tasks

### 1. Register Azure Application

- Go to **Azure Portal** → **App registrations**
- Click **New registration**
  - Name: `spn-databricks-sandbox`
  - Supported types: **Single tenant**
  - Leave Redirect URI blank
- Click **Register**

> ✅ Copy these:
> - `Application (client) ID` → used as `AZURE_CLIENT_ID`
> - `Directory (tenant) ID` → used as `AZURE_TENANT_ID`

---

### 2. Assign Role in Azure

- Go to **Subscriptions** → Your subscription
- Click **Access Control (IAM)** → **+ Add** → **Add role assignment**
  - Role: `Contributor`
  - Assign access to: `User, group, or service principal`
  - Select: `spn-databricks-sandbox`
- Save ✅

---

### 3. Add Federated Credentials

- Go to **App Registrations** → Your App
- Left menu: **Certificates & Secrets** → **Federated Credentials**
- Click **+ Add Credential**
  - **Name:** `github-actions-main`
  - **Issuer:** `https://token.actions.githubusercontent.com`
  - **Subject Identifier:**  
    `repo:<your-org>/<your-repo>:ref:refs/heads/main`
  - **Audience:** `api://AzureADTokenExchange`
- Save ✅

---

### 4. Set GitHub Repository Variables

Go to **GitHub → Settings → Secrets and variables → Actions → Variables**

| Name | Value |
|------|-------|
| `AZURE_CLIENT_ID` | Application (client) ID |
| `AZURE_TENANT_ID` | Directory (tenant) ID |
| `AZURE_SUBSCRIPTION_ID` | From `az account show` |
| `AZURE_LOCATION` | `eastus` or preferred region |
| `RESOURCE_GROUP` | Will be used in Terraform |

---

### 5. Test GitHub OIDC Login

Create a workflow: `.github/workflows/test-azure-login.yml`

```yaml
name: Test Azure Login

on:
  workflow_dispatch:
  
  push:
    branches: [ "main" ]

jobs:
  login:
    runs-on: ubuntu-latest
    permissions:
    #   id-token: write is required for Azure Login with OIDC
      id-token: write
      contents: read

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Azure Login with OIDC
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Show current Azure subscription
        run: az account show

```

Trigger it via GitHub Actions UI → ✅ You’re authenticated!

---

## ✅ Outcome

- Azure CLI and subscription access validated
- GitHub Actions connected via OIDC
- Ready to deploy infrastructure using Terraform
