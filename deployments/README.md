
# 📄 GitHub Actions Documentation

This document outlines the GitHub Actions workflows used in the project, categorized by purpose and functionality.

---

## 🔧 1. Frontend Build and Push to Azure ACR
**File:** `frontend.yml`

### Purpose
Builds a React frontend application, packages it with Docker, and pushes it to Azure Container Registry (ACR).

### Triggers
- On push to `main` branch
- Manual dispatch (`workflow_dispatch`)

### Key Steps
1. **Checkout Code**
   - Uses `actions/checkout@v2` to pull the latest code.
2. **Set up Node.js**
   - Uses `actions/setup-node@v3` to install Node v18.
3. **Build Frontend**
   - Runs `npm install` and `npm run build` to build React assets.
4. **Login to Azure**
   - Uses `azure/login@v1` with service principal credentials.
5. **Docker Build & Push**
   - Builds Docker image from `frontend/Dockerfile`.
   - Tags it with `${{ github.sha }}` and pushes to ACR.

---

## 🛠️ 2. Go API Deployment with Docker
**File:** `goapi-deployment.yml`

### Purpose
Builds a Golang API application using Docker and pushes the image to ACR.

### Triggers
- On push to `main` branch
- Manual trigger (`workflow_dispatch`)

### Key Steps
1. **Checkout Code**
2. **Login to Azure**
   - Authenticates against ACR using SP credentials.
3. **Build Docker Image**
   - Multi-stage Docker build for `goapi`.
   - Uses `Dockerfile` located in `apps/go-api/`.
4. **Push to ACR**
   - Tags and pushes using SHA for versioning.

---

## ⚙️ 3. Databricks Trigger Job
**File:** `dbx-trigger.yml`

### Purpose
Automates triggering of Databricks jobs via REST API.

### Triggers
- On push to `main`
- Manual dispatch

### Key Steps
1. **Checkout**
2. **Trigger Databricks Job**
   - Uses `curl` with `Authorization: Bearer ${{ secrets.DATABRICKS_TOKEN }}`
   - API POST to `api/2.1/jobs/run-now` with job ID payload.

---

## 🔐 4. Azure Login Test
**File:** `test-azure-login.yml`

### Purpose
Validates Azure login using the GitHub secrets to ensure credentials work.

### Triggers
- Manual only (`workflow_dispatch`)

### Key Steps
1. **Azure Login**
   - Uses `azure/login@v1` with client ID, tenant ID, and secret.
2. **List Subscriptions**
   - Runs `az account show` for validation.
---
## 📝 5. Kubes Manifest and Databricks Sample Workflow
**Folder:** `deployments/`

### Purpose
Contains a sample Databricks job YAML and a Kubernetes manifest for deploying the Go API application.

### Files

- `deployments/dbx/deploy.sh`: sample script to trigger Databricks job
- `deployments/k8s-manifasts.yml`: sample Kubernetes manifest for `goapi` and `react-front` deployment
---

## 🗂️ ACR & Resource Details
- Azure Container Registry: `${{ secrets.REGISTRY_NAME }}.azurecr.io`
- Frontend image: `frontend`
- Backend image: `goapi`
- Databricks Job ID: `${{ secrets.DATABRICKS_JOB_ID }}`

---

## 🔒 Security Note
- All secrets (like ACR creds, Azure SP creds, Databricks token) are securely stored in GitHub Secrets.
- Never hard-code them in YAML or source files.
