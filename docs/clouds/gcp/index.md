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

### Use an existing project

If you already have a GCP project, list your projects and activate the one you want:

```bash
# List all projects you have access to
gcloud projects list

# Output example:
# PROJECT_ID              NAME          PROJECT_NUMBER
# my-project-123          My Project    123456789012
# my-other-project        Other         987654321098

# Set the active project
gcloud config set project my-project-123

# Confirm it's set
gcloud config get project
```

Then skip ahead to [link billing](#link-a-billing-account) if not already linked, or go straight to [Phase 3](#phase-3-enable-the-vertex-ai-api-and-create-an-api-key).

### Create a new project

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

## Troubleshooting

### `invalid_grant` — Stale or Expired Tokens

The `invalid_grant` error means your local security tokens are stale or corrupted. Common causes:

- You haven't logged in for a while and the tokens expired
- Your Google account password changed, immediately invalidating all local tokens
- Your project is in **"Testing"** mode on the OAuth Consent Screen — user tokens expire every **7 days** in this mode
- You manually revoked the "Google Cloud SDK" app from your Google Account security settings

#### Fix: Refresh both login types

Run these two commands in order. Each opens a browser window — use the **same Google account** for both:

```bash
# 1. Refresh the main CLI login
gcloud auth login

# 2. Refresh the Application Default Credentials (used by SDKs and LibreChat)
gcloud auth application-default login
```

#### Fix: Re-set the quota project

After refreshing tokens, re-link your project for billing attribution:

```bash
gcloud auth application-default set-quota-project YOUR_PROJECT_ID
```

To keep the CLI config and ADC in sync at all times, also set:

```bash
gcloud config set billing/quota_project YOUR_PROJECT_ID
```

#### Verify everything is working

```bash
gcloud auth application-default print-access-token
```

If this prints a long string starting with `ya29...`, you are back in business.

!!! tip "Understanding the two login commands"
    - `gcloud auth login` — authenticates **you** as a user for running `gcloud` CLI commands
    - `gcloud auth application-default login` — creates credentials that **applications and SDKs** (like LibreChat) use at runtime

    These are stored separately and both can expire independently, which is why you need to refresh both.

!!! note "Stop tokens expiring every 7 days"
    If your project's OAuth Consent Screen is set to **"Testing"**, tokens expire weekly. To fix this permanently, go to **APIs & Services → OAuth Consent Screen** in the GCP Console and publish the app to **"Production"** (no formal review needed for internal/personal projects).

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
