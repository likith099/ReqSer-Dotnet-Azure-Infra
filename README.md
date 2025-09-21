# Azure Infrastructure as Code for .NET Applications

This repository contains Infrastructure as Code (IaC) templates and CI/CD pipelines for deploying .NET applications to Azure using the free tier resources.

## 🏗️ Architecture

The infrastructure includes:
- **Azure App Service Plan** (Free tier F1)
- **Azure Web App** (Linux-based, .NET 8.0)
- **Resource Group** for organizing resources

## 📁 Project Structure

```
├── bicep/                          # Bicep infrastructure templates
│   ├── main.bicep                  # Main App Service template
│   └── deploy.bicep                # Subscription-level deployment
├── parameters/                     # Environment-specific parameters
│   ├── dev.parameters.json         # Development environment
│   ├── staging.parameters.json     # Staging environment
│   └── prod.parameters.json        # Production environment
├── pipelines/                      # Azure DevOps YAML pipelines
│   ├── azure-infrastructure.yml    # Infrastructure deployment
│   └── azure-app-deploy.yml        # Application deployment
├── .github/workflows/              # GitHub Actions workflows
│   ├── infrastructure.yml          # Infrastructure deployment
│   └── deploy-app.yml               # Application deployment
└── README.md                       # This file
```

## 🚀 Quick Start

### Prerequisites

1. **Azure Subscription** with appropriate permissions
2. **Azure CLI** installed and configured
3. **Bicep CLI** installed
4. **.NET 8 SDK** for application development
5. **Git** for version control

### Local Development Setup

1. **Clone the repository:**
   ```bash
   git clone <your-repo-url>
   cd Infra-pipeline
   ```

2. **Install Azure CLI and Bicep:**
   ```bash
   # Install Azure CLI (Windows)
   winget install Microsoft.AzureCLI
   
   # Install Bicep
   az bicep install
   ```

3. **Login to Azure:**
   ```bash
   az login
   az account set --subscription "<your-subscription-id>"
   ```

## 🔧 Manual Deployment

### Deploy Infrastructure

1. **Deploy using Bicep:**
   ```bash
   # Deploy to subscription level
   az deployment sub create \
     --location "East US" \
     --template-file bicep/deploy.bicep \
     --parameters resourceGroupName="rg-dotnet-app-manual" \
                 location="East US" \
                 webAppName="webapp-dotnet-manual"
   ```

2. **Deploy with parameter files:**
   ```bash
   # Deploy development environment
   az deployment sub create \
     --location "East US" \
     --template-file bicep/deploy.bicep \
     --parameters @parameters/dev.parameters.json
   ```

### Deploy Application

1. **Build and publish your .NET app:**
   ```bash
   dotnet publish --configuration Release --output ./publish
   ```

2. **Deploy to App Service:**
   ```bash
   az webapp deployment source config-zip \
     --resource-group "rg-dotnet-app-manual" \
     --name "webapp-dotnet-manual" \
     --src "./publish.zip"
   ```

## 🔄 CI/CD Setup

### Option 1: Azure DevOps

1. **Create Service Connection:**
   - Go to Azure DevOps → Project Settings → Service connections
   - Create new Azure Resource Manager connection
   - Name it `azure-service-connection`

2. **Set Pipeline Variables:**
   ```yaml
   variables:
     AZURE_SUBSCRIPTION_ID: 'your-subscription-id'
   ```

3. **Create Pipelines:**
   - Import `pipelines/azure-infrastructure.yml` for infrastructure
   - Import `pipelines/azure-app-deploy.yml` for application deployment

### Option 2: GitHub Actions

1. **Set up Azure Credentials:**
   - Create a service principal:
     ```bash
     az ad sp create-for-rbac --name "github-actions-sp" --role contributor \
       --scopes /subscriptions/<subscription-id> --sdk-auth
     ```
   - Add the JSON output as `AZURE_CREDENTIALS` secret in GitHub

2. **Configure Repository Secrets:**
   - `AZURE_CREDENTIALS`: Service principal JSON from step 1
   - `WEB_APP_NAME`: Your web app name (optional)
   - `RESOURCE_GROUP_NAME`: Your resource group name (optional)

3. **Configure Repository Variables:**
   - `WEB_APP_NAME`: Default web app name
   - `RESOURCE_GROUP_NAME`: Default resource group name

## 🌍 Environment Configuration

### Development Environment
- **Resource Group:** `rg-dotnet-app-dev`
- **Web App:** `webapp-dotnet-dev`
- **SKU:** F1 (Free)

### Staging Environment
- **Resource Group:** `rg-dotnet-app-staging`
- **Web App:** `webapp-dotnet-staging`
- **SKU:** F1 (Free)

### Production Environment
- **Resource Group:** `rg-dotnet-app-prod`
- **Web App:** `webapp-dotnet-prod`
- **SKU:** F1 (Free)

## 🔒 Security Considerations

1. **Service Principal Permissions:**
   - Use least privilege principle
   - Scope permissions to specific resource groups when possible

2. **Secrets Management:**
   - Never commit secrets to repository
   - Use Azure Key Vault for production secrets
   - Rotate service principal credentials regularly

3. **Network Security:**
   - HTTPS is enforced by default
   - FTPS is disabled
   - Consider adding custom domains with SSL certificates

## 💰 Cost Optimization

This setup uses Azure free tier resources:
- **App Service Plan F1:** Free (includes 1GB storage, 165 minutes/day compute)
- **Resource Group:** No cost
- **Web App:** Included in App Service Plan

**Limitations of Free Tier:**
- No custom domains with SSL
- No scaling capabilities
- Limited compute time (165 minutes/day)
- No production SLA

## 🐛 Troubleshooting

### Common Issues

1. **Deployment Fails - Name Already Exists:**
   ```bash
   # Use unique names with timestamps or GUIDs
   webAppName="webapp-dotnet-$(date +%s)"
   ```

2. **Free Tier Quotas Exceeded:**
   - Check Azure portal for quota usage
   - Consider upgrading to Basic tier (B1) if needed

3. **Build Fails:**
   ```bash
   # Ensure .NET SDK version matches pipeline
   dotnet --version
   ```

4. **Permission Denied:**
   ```bash
   # Verify service principal has Contributor role
   az role assignment list --assignee <service-principal-id>
   ```

### Useful Commands

```bash
# Check deployment status
az deployment sub show --name "deployment-name"

# View App Service logs
az webapp log tail --name "webapp-name" --resource-group "rg-name"

# List all resources in resource group
az resource list --resource-group "rg-name" --output table

# Get web app URL
az webapp show --name "webapp-name" --resource-group "rg-name" --query defaultHostName
```

## 📚 Additional Resources

- [Azure App Service Documentation](https://docs.microsoft.com/en-us/azure/app-service/)
- [Azure Bicep Documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Azure DevOps Documentation](https://docs.microsoft.com/en-us/azure/devops/)
- [GitHub Actions for Azure](https://docs.github.com/en/actions/deployment/deploying-to-your-cloud-provider/deploying-to-azure)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the deployment
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Note:** This setup is optimized for the Azure free tier and is suitable for development, testing, and small-scale applications. For production workloads, consider upgrading to paid tiers with better performance and SLA guarantees.