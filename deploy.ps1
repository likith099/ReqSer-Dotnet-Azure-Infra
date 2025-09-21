# Azure Infrastructure Deployment Script (PowerShell)
# This script deploys the infrastructure for .NET application hosting

param(
    [string]$Location = "East US",
    [string]$ResourceGroupName = "",
    [string]$WebAppName = ""
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Configuration
$Timestamp = Get-Date -Format "yyyyMMddHHmmss"
if (-not $ResourceGroupName) {
    $ResourceGroupName = "rg-dotnet-app-$Timestamp"
}
if (-not $WebAppName) {
    $WebAppName = "webapp-dotnet-$Timestamp"
}
$DeploymentName = "infrastructure-deployment-$Timestamp"

# Functions
function Write-Header {
    param([string]$Message)
    Write-Host "================================" -ForegroundColor Blue
    Write-Host $Message -ForegroundColor Blue
    Write-Host "================================" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Cyan
}

# Check prerequisites
function Test-Prerequisites {
    Write-Header "Checking Prerequisites"
    
    # Check if Azure CLI is installed
    try {
        $null = Get-Command az -ErrorAction Stop
        Write-Success "Azure CLI is installed"
    }
    catch {
        Write-Error "Azure CLI is not installed. Please install it first."
        exit 1
    }
    
    # Check if Bicep is installed
    try {
        az bicep version 2>$null | Out-Null
        Write-Success "Bicep is available"
    }
    catch {
        Write-Warning "Bicep is not installed. Installing now..."
        az bicep install
        Write-Success "Bicep installed successfully"
    }
    
    # Check if user is logged in
    try {
        $account = az account show 2>$null | ConvertFrom-Json
        Write-Success "Logged in to Azure"
        
        # Display current subscription
        Write-Info "Current subscription: $($account.name) ($($account.id))"
    }
    catch {
        Write-Error "Not logged in to Azure. Please run 'az login' first."
        exit 1
    }
}

# Validate Bicep templates
function Test-BicepTemplates {
    Write-Header "Validating Bicep Templates"
    
    Write-Info "Validating deployment template..."
    
    $validateCommand = @(
        "deployment", "sub", "validate",
        "--location", $Location,
        "--template-file", "bicep/deploy.bicep",
        "--parameters", "resourceGroupName=$ResourceGroupName",
                       "location=$Location",
                       "webAppName=$WebAppName"
    )
    
    & az @validateCommand
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Template validation passed"
    } else {
        Write-Error "Template validation failed"
        exit 1
    }
}

# Deploy infrastructure
function Deploy-Infrastructure {
    Write-Header "Deploying Infrastructure"
    
    Write-Info "Deploying to subscription level..."
    Write-Info "Resource Group: $ResourceGroupName"
    Write-Info "Web App Name: $WebAppName"
    Write-Info "Location: $Location"
    
    $deployCommand = @(
        "deployment", "sub", "create",
        "--location", $Location,
        "--template-file", "bicep/deploy.bicep",
        "--parameters", "resourceGroupName=$ResourceGroupName",
                       "location=$Location",
                       "webAppName=$WebAppName",
        "--name", $DeploymentName
    )
    
    & az @deployCommand
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Infrastructure deployment completed"
    } else {
        Write-Error "Infrastructure deployment failed"
        exit 1
    }
}

# Get deployment outputs
function Get-DeploymentOutputs {
    Write-Header "Deployment Results"
    
    # Get outputs from deployment
    $webAppUrl = az deployment sub show --name $DeploymentName --query properties.outputs.webAppUrl.value --output tsv
    $actualWebAppName = az deployment sub show --name $DeploymentName --query properties.outputs.webAppName.value --output tsv
    $actualRgName = az deployment sub show --name $DeploymentName --query properties.outputs.resourceGroupName.value --output tsv
    
    Write-Success "Deployment completed successfully!"
    Write-Host ""
    Write-Info "Deployment Details:"
    Write-Host "  🌐 Web App URL: $webAppUrl" -ForegroundColor White
    Write-Host "  📱 Web App Name: $actualWebAppName" -ForegroundColor White
    Write-Host "  📦 Resource Group: $actualRgName" -ForegroundColor White
    Write-Host "  🕒 Deployment Name: $DeploymentName" -ForegroundColor White
    Write-Host ""
    Write-Info "Next Steps:"
    Write-Host "  1. Build and publish your .NET application" -ForegroundColor White
    Write-Host "  2. Deploy your application using:" -ForegroundColor White
    Write-Host "     az webapp deployment source config-zip ``" -ForegroundColor Gray
    Write-Host "       --resource-group `"$actualRgName`" ``" -ForegroundColor Gray
    Write-Host "       --name `"$actualWebAppName`" ``" -ForegroundColor Gray
    Write-Host "       --src `"./publish.zip`"" -ForegroundColor Gray
    Write-Host ""
    Write-Info "To clean up resources later:"
    Write-Host "  az group delete --name `"$actualRgName`" --yes --no-wait" -ForegroundColor Gray
    
    # Save outputs to file for later use
    $outputs = @{
        WebAppUrl = $webAppUrl
        WebAppName = $actualWebAppName
        ResourceGroupName = $actualRgName
        DeploymentName = $DeploymentName
        Timestamp = $Timestamp
    }
    
    $outputs | ConvertTo-Json | Out-File -FilePath "deployment-outputs.json" -Encoding UTF8
    Write-Info "Deployment outputs saved to deployment-outputs.json"
}

# Main execution
function Main {
    Write-Header "Azure Infrastructure Deployment"
    Write-Host "This script will deploy infrastructure for hosting a .NET application on Azure" -ForegroundColor White
    Write-Host ""
    
    # Ask for confirmation
    $confirm = Read-Host "Do you want to proceed with deployment? (y/N)"
    if ($confirm -notmatch "^[Yy]$") {
        Write-Info "Deployment cancelled"
        exit 0
    }
    
    try {
        Test-Prerequisites
        Test-BicepTemplates
        Deploy-Infrastructure
        Get-DeploymentOutputs
        
        Write-Success "🎉 All done! Your infrastructure is ready for deployment."
    }
    catch {
        Write-Error "An error occurred: $($_.Exception.Message)"
        exit 1
    }
}

# Run the script
Main