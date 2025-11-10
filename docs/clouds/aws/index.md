# Amazon Web Services (AWS)

Cloud infrastructure and services configuration guide with security-first credential management.

## Overview

AWS provides scalable cloud computing services. This section covers secure setup, CLI configuration, and best practices for managing AWS credentials with proper scope isolation.

## Installing AWS CLI v2

AWS CLI v2 is the recommended command-line interface for AWS services.

### Linux/WSL Installation

One-liner to download, extract, install, and verify:

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip && sudo ./aws/install && aws --version && rm -rf aws awscliv2.zip
```

### macOS Installation

**Using Homebrew (Recommended):**

```bash
brew install awscli && aws --version
```

**Or manually:**

One-liner to download, extract, install, and verify:

```bash
curl "https://awscli.amazonaws.com/awscli-exe-macos.zip" -o "awscliv2.zip" && unzip awscliv2.zip && sudo ./aws/install && aws --version && rm -rf aws awscliv2.zip
```

## AWS Credential Setup

### Understanding Credential Files

AWS uses two configuration files:

- **`~/.aws/credentials`** - Contains access keys (API credentials)
- **`~/.aws/config`** - Contains region and profile configuration

### Creating AWS Credentials via CLI

The easiest way to set up credentials is using the AWS CLI interactive configuration:

```bash
aws configure
```

This prompts for:
1. AWS Access Key ID
2. AWS Secret Access Key
3. Default region
4. Default output format

However, **this creates a default profile with broad permissions**. For better security, follow the profile-based approach below.

## Security-First Credential Management

### Critical Security Principle

**Never use static credentials with broad AWS permissions as your default profile.** Instead:

1. Use temporary credentials or IAM roles when possible
2. Keep static credentials in separate, narrowly-scoped profiles
3. Grant only the minimum permissions needed for each profile

### Setting Up Service-Specific Profiles

Create isolated credential profiles for each service. For example, to set up a Bedrock-only profile:

```bash
aws configure --profile bedrock
```

Enter your credentials when prompted. This creates:

**In `~/.aws/credentials`:**

```ini
[bedrock]
aws_access_key_id = YOUR_ACCESS_KEY_ID
aws_secret_access_key = YOUR_SECRET_ACCESS_KEY
```

**In `~/.aws/config`:**

```ini
[profile bedrock]
region = us-west-2
output = json
```

### Complete Profile Configuration Example

For multiple services with proper isolation:

**`~/.aws/credentials`**

```ini
# Bedrock (Claude API access only)
[bedrock]
aws_access_key_id = AKIA...
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG...

# S3 (Storage only)
[s3-user]
aws_access_key_id = AKIA...
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG...
```

**`~/.aws/config`**

```ini
# Bedrock Profile - Bedrock service only
[profile bedrock]
region = us-west-2
output = json

# S3 Profile - S3 access only
[profile s3-user]
region = us-west-2
output = json
```

### IAM Policy Examples

When creating AWS access keys for a profile, apply strict IAM policies:

**Bedrock-Only Policy:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream"
      ],
      "Resource": "*"
    }
  ]
}
```

**S3-Only Policy:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::my-bucket",
        "arn:aws:s3:::my-bucket/*"
      ]
    }
  ]
}
```

## Using Profiles with AWS CLI

### Override Default Profile

Use any configured profile with the `--profile` flag:

```bash
# Use bedrock profile
aws s3 ls --profile bedrock

# Use s3-user profile
aws s3 ls --profile s3-user
```

### Set Default Profile for Session

```bash
export AWS_PROFILE=bedrock
aws s3 ls  # Uses bedrock profile
```

### Using Profiles with AWS SDKs

Most AWS SDKs (Python boto3, Node.js, etc.) respect the `AWS_PROFILE` environment variable:

```bash
export AWS_PROFILE=bedrock
python script.py  # Script uses bedrock credentials
```

## Credentials File Security

Ensure proper permissions on credential files:

```bash
chmod 700 ~/.aws
chmod 600 ~/.aws/credentials
chmod 600 ~/.aws/config
```

Never commit credential files to version control:

```bash
# In .gitignore
~/.aws/credentials
~/.aws/config
```

## Best Practices

### Profile Isolation

- ✅ **DO**: Create separate profiles for each service/application
- ❌ **DON'T**: Use default profile with full AWS permissions

### Credential Rotation

- ✅ **DO**: Rotate access keys regularly (quarterly minimum)
- ❌ **DON'T**: Reuse the same credentials across multiple systems

### Least Privilege

- ✅ **DO**: Grant only the permissions each service needs
- ❌ **DON'T**: Attach broad policies like `AdministratorAccess`

### Monitoring

- ✅ **DO**: Enable CloudTrail to audit credential usage
- ✅ **DO**: Check CloudWatch for unusual activity
- ❌ **DON'T**: Ignore access logs

### Temporary Credentials

- ✅ **PREFER**: Temporary credentials via STS AssumeRole (when possible)
- ❌ **AVOID**: Long-lived static credentials for high-privilege access
