# Cloud Platforms

Guide to major cloud service providers and their configuration for development and deployment.

## Supported Platforms

- **[AWS](aws/index.md)** - Amazon Web Services
- **[Azure](azure/index.md)** - Microsoft Azure
- **[Google Cloud](gcp/index.md)** - Google Cloud Platform

## Choosing a Cloud Provider

| Feature | AWS | Azure | GCP |
|---------|-----|-------|-----|
| **Services** | Broadest portfolio | Enterprise integration | Data/ML focused |
| **Global Reach** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **ML/AI** | SageMaker, Bedrock | Cognitive Services | Vertex AI |
| **S3 or compatible storage** | Yes | No | Yes |
| **Best For** | General purpose | Microsoft ecosystem | Data science |

## Common Setup Patterns

Each cloud provider section includes:

1. **CLI Installation** - Command-line tools
2. **Authentication Setup** - Credentials and configuration
3. **Service-Specific Profiles** - Isolated, scoped access
4. **Best Practices** - Security and cost optimization
5. **Common Use Cases** - Getting started examples

## Security Principles

Across all cloud providers:

- ✅ Use service-specific profiles/roles
- ✅ Apply least-privilege IAM policies
- ✅ Rotate credentials regularly
- ✅ Use temporary/session credentials when possible
- ✅ Enable audit logging (CloudTrail, Activity Log, Cloud Audit Logs)
- ❌ Never use admin credentials for routine work
- ❌ Don't commit credentials to version control

## Next Steps

- Start with your primary cloud provider
- Configure authentication and credentials
- Create service-specific profiles for applications
- Review IAM policies for least privilege
- Enable cost monitoring and alerts
