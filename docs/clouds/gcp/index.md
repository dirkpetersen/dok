# Google Cloud Platform (GCP)

Cloud infrastructure and services configuration guide for Google Cloud.

## Overview

Google Cloud Platform excels in data analytics, machine learning, and Kubernetes. This section covers setup, CLI configuration, and best practices for GCP development — including AI/LLM API access via Vertex AI.

## Phase 1: Install gcloud CLI

On Ubuntu/Debian, install the Google Cloud SDK via apt:

```bash
# 1. Update and install dependencies
sudo apt-get update && sudo apt-get install apt-transport-https ca-certificates gnupg curl -y

# 2. Add Google Cloud public key
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg

# 3. Add the gcloud repo
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

# 4. Install the CLI
sudo apt-get update && sudo apt-get install google-cloud-cli -y
```

Verify the installation:

```bash
gcloud version
```

## Phase 2: Create a Project and Link Billing

You need a project and an attached billing account before you can use Vertex AI or any paid GCP service.

### Log in

```bash
gcloud auth login
```

This opens a browser window for authentication. In headless environments (e.g. WSL without a browser), append `--no-launch-browser` and follow the printed URL manually.

### Create a project

Choose a globally unique project ID (lowercase letters, digits, hyphens):

```bash
gcloud projects create librechat-vertex-101 --name="LibreChat AI"
gcloud config set project librechat-vertex-101
```

### Link a billing account

```bash
# Find your billing account ID (format: 0X0X0X-0X0X0X-0X0X0X)
gcloud billing accounts list

# Link the billing account to your project
gcloud billing projects link librechat-vertex-101 --billing-account=YOUR_BILLING_ID
```

!!! warning "Billing required"
    Vertex AI usage incurs charges. Without a linked billing account, API calls will fail with a 403 error even after enabling the service.

## Phase 3: Enable the Vertex AI API and Create an API Key

### Enable Vertex AI

```bash
gcloud services enable aiplatform.googleapis.com
```

### Create an API key

```bash
gcloud services api-keys create --display-name="LibreChat-Vertex-Key"
```

### Retrieve the key string

```bash
gcloud services api-keys list
```

Look for the `KEY_STRING` column in the output. Copy that value — it starts with `AIzaSy...`. You will need it in Phase 5.

## Phase 4: Restrict the API Key (Security)

An unrestricted API key can be used to call any enabled GCP service. Restrict yours so it can only invoke Vertex AI.

### Find the key's resource name

From the `gcloud services api-keys list` output, copy the `NAME` field. It looks like:

```
projects/123456789/locations/global/keys/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

### Apply the restriction

```bash
gcloud services api-keys update KEY_NAME \
  --api-target=service=aiplatform.googleapis.com
```

Replace `KEY_NAME` with the full resource name from the previous step.

!!! tip "Why this matters"
    If your key leaks (e.g. committed to a public repo), an attacker can only call Vertex AI — not spin up VMs, modify storage, or access other services. Always restrict keys to the minimum required surface.

## Phase 5: Configure LibreChat (.env)

Add these variables to your LibreChat `.env` file:

```bash
# The key string from Phase 3
GOOGLE_KEY=AIzaSy...your_key_here

# The project ID from Phase 2
GOOGLE_CLOUD_PROJECT=librechat-vertex-101

# Region where your models are served
GOOGLE_CLOUD_LOCATION=us-central1
```

!!! note "403 Permission Denied?"
    This usually means one of:

    - Billing is not linked to the project
    - The API key restriction is blocking the call (check the service name matches)
    - The Vertex AI API was not enabled (`gcloud services enable aiplatform.googleapis.com`)

## Optional: Set a Budget Alert

Protect yourself from unexpected charges by creating a billing alert via the CLI. Google will email you when spending crosses your threshold.

```bash
# List available billing budgets (requires billing.budgets.get permission)
gcloud billing budgets list --billing-account=YOUR_BILLING_ID

# Create a $10 alert that emails you at 50%, 90%, and 100% of budget
gcloud billing budgets create \
  --billing-account=YOUR_BILLING_ID \
  --display-name="LibreChat Monthly Cap" \
  --budget-amount=10USD \
  --threshold-rule=percent=0.5 \
  --threshold-rule=percent=0.9 \
  --threshold-rule=percent=1.0
```

!!! note
    Budget alerts require the `billing.budgets.create` IAM permission on the billing account. If you get a permission error, create the alert in the GCP Console under **Billing → Budgets & alerts** instead.

## Best Practices

### Key hygiene

- ✅ **DO**: Restrict every API key to specific services
- ✅ **DO**: Rotate keys regularly and revoke unused ones
- ❌ **DON'T**: Commit API keys to version control — use `.env` files excluded by `.gitignore`

### Project isolation

- ✅ **DO**: Use separate projects for dev, staging, and production
- ✅ **DO**: Set per-project billing budgets and alerts
- ❌ **DON'T**: Share credentials across unrelated applications

### Least privilege

- ✅ **PREFER**: Service accounts with narrowly scoped IAM roles over API keys for server-to-server calls
- ✅ **PREFER**: Workload Identity Federation for CI/CD pipelines instead of long-lived keys
