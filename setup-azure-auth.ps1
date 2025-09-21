# Quick Azure OIDC Setup for GitHub Actions
# Run this script to set up authentication for your GitHub repository

param(
    [string]$GitHubOrg = "likith099",
    [string]$GitHubRepo = "ReqSer-Dotnet-Azure-Infra",
    [string]$AppName = "github-actions-oidc-dotnet"
)

Write-Host "🚀 Setting up Azure OIDC for GitHub Actions..." -ForegroundColor Green
Write-Host "Repository: $GitHubOrg/$GitHubRepo" -ForegroundColor Cyan

try {
    # Check if logged in to Azure
    $account = az account show 2>$null | ConvertFrom-Json
    if (-not $account) {
        Write-Host "❌ Not logged in to Azure. Please run 'az login' first." -ForegroundColor Red
        exit 1
    }
    
    $subscriptionId = $account.id
    $tenantId = $account.tenantId
    
    Write-Host "✅ Logged in to Azure" -ForegroundColor Green
    Write-Host "   Subscription: $($account.name) ($subscriptionId)" -ForegroundColor Gray
    Write-Host "   Tenant: $tenantId" -ForegroundColor Gray
    
    # Create app registration
    Write-Host "📝 Creating app registration..." -ForegroundColor Yellow
    $appId = az ad app create --display-name $AppName --query appId --output tsv
    
    if (-not $appId) {
        throw "Failed to create app registration"
    }
    
    Write-Host "✅ App registration created: $appId" -ForegroundColor Green
    
    # Create service principal
    Write-Host "👤 Creating service principal..." -ForegroundColor Yellow
    az ad sp create --id $appId | Out-Null
    
    # Assign contributor role
    Write-Host "🔐 Assigning Contributor role..." -ForegroundColor Yellow
    az role assignment create --assignee $appId --role Contributor --scope "/subscriptions/$subscriptionId" | Out-Null
    
    # Create federated credentials for main branch
    Write-Host "🔗 Creating federated credentials for main branch..." -ForegroundColor Yellow
    $mainCredential = @{
        name = "github-main"
        issuer = "https://token.actions.githubusercontent.com"
        subject = "repo:$GitHubOrg/${GitHubRepo}:ref:refs/heads/main"
        description = "GitHub Actions for main branch"
        audiences = @("api://AzureADTokenExchange")
    } | ConvertTo-Json -Compress
    
    az ad app federated-credential create --id $appId --parameters $mainCredential | Out-Null
    
    # Create federated credentials for pull requests
    Write-Host "🔗 Creating federated credentials for pull requests..." -ForegroundColor Yellow
    $prCredential = @{
        name = "github-pr"
        issuer = "https://token.actions.githubusercontent.com"
        subject = "repo:$GitHubOrg/${GitHubRepo}:pull_request"
        description = "GitHub Actions for pull requests"
        audiences = @("api://AzureADTokenExchange")
    } | ConvertTo-Json -Compress
    
    az ad app federated-credential create --id $appId --parameters $prCredential | Out-Null
    
    Write-Host ""
    Write-Host "🎉 Setup completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Go to your GitHub repository settings:" -ForegroundColor White
    Write-Host "   https://github.com/$GitHubOrg/$GitHubRepo/settings/secrets/actions" -ForegroundColor Blue
    Write-Host ""
    Write-Host "2. Add these Repository Secrets:" -ForegroundColor White
    Write-Host "   AZURE_CLIENT_ID     = $appId" -ForegroundColor Gray
    Write-Host "   AZURE_TENANT_ID     = $tenantId" -ForegroundColor Gray
    Write-Host "   AZURE_SUBSCRIPTION_ID = $subscriptionId" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Commit and push your updated workflow files" -ForegroundColor White
    Write-Host ""
    Write-Host "🔍 To verify the setup:" -ForegroundColor Cyan
    Write-Host "   az ad app show --id $appId --query '{displayName:displayName, appId:appId}'" -ForegroundColor Gray
    
    # Save the configuration for reference
    $config = @{
        appId = $appId
        tenantId = $tenantId
        subscriptionId = $subscriptionId
        githubRepo = "$GitHubOrg/$GitHubRepo"
        createdDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    $config | ConvertTo-Json -Depth 2 | Out-File -FilePath "azure-oidc-config.json" -Encoding UTF8
    Write-Host "💾 Configuration saved to azure-oidc-config.json" -ForegroundColor Gray
    
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please check your Azure CLI installation and permissions." -ForegroundColor Yellow
    exit 1
}