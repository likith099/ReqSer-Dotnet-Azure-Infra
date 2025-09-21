# Azure Authentication Setup for GitHub Actions

This guide will help you set up Azure authentication for your GitHub Actions workflows.

## 🔐 Method 1: Using OpenID Connect (OIDC) - **RECOMMENDED**

This is the modern, more secure approach that doesn't require storing long-lived secrets.

### Step 1: Create an Azure App Registration

```powershell
# Login to Azure
az login

# Get your subscription ID
$subscriptionId = az account show --query id --output tsv
Write-Host "Subscription ID: $subscriptionId"

# Create the app registration
$appName = "github-actions-oidc"
$app = az ad app create --display-name $appName --query appId --output tsv
Write-Host "App ID (Client ID): $app"

# Create a service principal
az ad sp create --id $app

# Get tenant ID
$tenantId = az account show --query tenantId --output tsv
Write-Host "Tenant ID: $tenantId"
```

### Step 2: Assign Permissions

```powershell
# Assign Contributor role to the service principal
az role assignment create --assignee $app --role Contributor --scope "/subscriptions/$subscriptionId"
```

### Step 3: Configure Federated Credentials

```powershell
# Replace with your GitHub repository details
$githubOrg = "likith099"
$githubRepo = "ReqSer-Dotnet-Azure-Infra"

# Create federated credential for main branch
az ad app federated-credential create --id $app --parameters @"
{
    \"name\": \"github-main\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:$githubOrg/${githubRepo}:ref:refs/heads/main\",
    \"description\": \"GitHub Actions for main branch\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
}
"@

# Create federated credential for pull requests
az ad app federated-credential create --id $app --parameters @"
{
    \"name\": \"github-pr\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:$githubOrg/${githubRepo}:pull_request\",
    \"description\": \"GitHub Actions for pull requests\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
}
"@
```

### Step 4: Configure GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions, and add these **Repository secrets**:

- `AZURE_CLIENT_ID`: `$app` (from step 1)
- `AZURE_TENANT_ID`: `$tenantId` (from step 1)  
- `AZURE_SUBSCRIPTION_ID`: `$subscriptionId` (from step 1)

### Step 5: Add Permissions to Workflow

Add these permissions to your GitHub Actions workflow files:

```yaml
permissions:
  id-token: write
  contents: read
```

## 🔐 Method 2: Using Service Principal with Secret

If you prefer the traditional approach with secrets:

### Step 1: Create Service Principal

```powershell
# Create service principal with secret
$sp = az ad sp create-for-rbac --name "github-actions-sp" --role contributor --scopes "/subscriptions/$subscriptionId" --sdk-auth | ConvertFrom-Json

# Display the credentials (save these securely)
Write-Host "Copy this entire JSON as AZURE_CREDENTIALS secret:"
$sp | ConvertTo-Json
```

### Step 2: Configure GitHub Secret

Add this **Repository secret** in GitHub:
- `AZURE_CREDENTIALS`: The complete JSON output from step 1

### Step 3: Update Workflow (if using this method)

Use this login step instead:

```yaml
- name: Azure Login
  uses: azure/login@v1
  with:
    creds: ${{ secrets.AZURE_CREDENTIALS }}
```

## 🚀 Quick Setup Script

Here's a complete PowerShell script to set up OIDC authentication:

```powershell
# Azure OIDC Setup for GitHub Actions
param(
    [Parameter(Mandatory=$true)]
    [string]$GitHubOrg,
    
    [Parameter(Mandatory=$true)]
    [string]$GitHubRepo,
    
    [string]$AppName = "github-actions-oidc"
)

# Login and get subscription info
az login
$subscriptionId = az account show --query id --output tsv
$tenantId = az account show --query tenantId --output tsv

Write-Host "Setting up Azure OIDC for GitHub Actions..." -ForegroundColor Green
Write-Host "Subscription: $subscriptionId" -ForegroundColor Cyan
Write-Host "Tenant: $tenantId" -ForegroundColor Cyan

# Create app registration
Write-Host "Creating app registration..." -ForegroundColor Yellow
$appId = az ad app create --display-name $AppName --query appId --output tsv

# Create service principal
Write-Host "Creating service principal..." -ForegroundColor Yellow
az ad sp create --id $appId

# Assign contributor role
Write-Host "Assigning Contributor role..." -ForegroundColor Yellow
az role assignment create --assignee $appId --role Contributor --scope "/subscriptions/$subscriptionId"

# Create federated credentials
Write-Host "Creating federated credentials..." -ForegroundColor Yellow

# Main branch credential
$mainCredential = @{
    name = "github-main"
    issuer = "https://token.actions.githubusercontent.com"
    subject = "repo:$GitHubOrg/${GitHubRepo}:ref:refs/heads/main"
    description = "GitHub Actions for main branch"
    audiences = @("api://AzureADTokenExchange")
} | ConvertTo-Json -Compress

az ad app federated-credential create --id $appId --parameters $mainCredential

# Pull request credential
$prCredential = @{
    name = "github-pr"
    issuer = "https://token.actions.githubusercontent.com"
    subject = "repo:$GitHubOrg/${GitHubRepo}:pull_request"
    description = "GitHub Actions for pull requests"
    audiences = @("api://AzureADTokenExchange")
} | ConvertTo-Json -Compress

az ad app federated-credential create --id $appId --parameters $prCredential

Write-Host "✅ Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Add these secrets to your GitHub repository:" -ForegroundColor Cyan
Write-Host "AZURE_CLIENT_ID: $appId" -ForegroundColor White
Write-Host "AZURE_TENANT_ID: $tenantId" -ForegroundColor White
Write-Host "AZURE_SUBSCRIPTION_ID: $subscriptionId" -ForegroundColor White
Write-Host ""
Write-Host "GitHub Repository Settings URL:" -ForegroundColor Cyan
Write-Host "https://github.com/$GitHubOrg/$GitHubRepo/settings/secrets/actions" -ForegroundColor Blue
```

## 🔍 Troubleshooting

### Common Issues:

1. **"Login failed" error**: Ensure all three secrets are set correctly in GitHub
2. **"Permission denied"**: Verify the service principal has Contributor role
3. **"Invalid audience"**: Check that federated credentials are configured correctly
4. **"Subject mismatch"**: Ensure the subject matches your repository and branch exactly

### Verification Commands:

```powershell
# Verify app registration
az ad app show --id $appId --query "{displayName:displayName, appId:appId}"

# Verify service principal
az ad sp show --id $appId --query "{displayName:displayName, appId:appId}"

# Verify role assignments
az role assignment list --assignee $appId --query "[].{principalName:principalName, roleDefinitionName:roleDefinitionName, scope:scope}"

# Verify federated credentials
az ad app federated-credential list --id $appId --query "[].{name:name, subject:subject}"
```

## 📝 Notes

- **OIDC method is recommended** for better security (no long-lived secrets)
- The service principal needs **Contributor** role on the subscription or resource group
- For production, consider scoping permissions to specific resource groups only
- Federated credentials are tied to specific GitHub repositories and branches