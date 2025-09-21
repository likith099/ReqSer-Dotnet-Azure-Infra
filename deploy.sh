#!/bin/bash

# Azure Infrastructure Deployment Script
# This script deploys the infrastructure for .NET application hosting

set -e  # Exit on any error

# Configuration
LOCATION="East US"
TIMESTAMP=$(date +"%Y%m%d%H%M%S")
RESOURCE_GROUP_NAME="rg-dotnet-app-${TIMESTAMP}"
WEB_APP_NAME="webapp-dotnet-${TIMESTAMP}"
DEPLOYMENT_NAME="infrastructure-deployment-${TIMESTAMP}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check if Azure CLI is installed
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install it first."
        exit 1
    fi
    print_success "Azure CLI is installed"
    
    # Check if Bicep is installed
    if ! az bicep version &> /dev/null; then
        print_warning "Bicep is not installed. Installing now..."
        az bicep install
    fi
    print_success "Bicep is available"
    
    # Check if user is logged in
    if ! az account show &> /dev/null; then
        print_error "Not logged in to Azure. Please run 'az login' first."
        exit 1
    fi
    print_success "Logged in to Azure"
    
    # Display current subscription
    SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    print_info "Current subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"
}

# Validate Bicep templates
validate_templates() {
    print_header "Validating Bicep Templates"
    
    print_info "Validating deployment template..."
    az deployment sub validate \
        --location "$LOCATION" \
        --template-file bicep/deploy.bicep \
        --parameters resourceGroupName="$RESOURCE_GROUP_NAME" \
                    location="$LOCATION" \
                    webAppName="$WEB_APP_NAME"
    
    print_success "Template validation passed"
}

# Deploy infrastructure
deploy_infrastructure() {
    print_header "Deploying Infrastructure"
    
    print_info "Deploying to subscription level..."
    print_info "Resource Group: $RESOURCE_GROUP_NAME"
    print_info "Web App Name: $WEB_APP_NAME"
    print_info "Location: $LOCATION"
    
    az deployment sub create \
        --location "$LOCATION" \
        --template-file bicep/deploy.bicep \
        --parameters resourceGroupName="$RESOURCE_GROUP_NAME" \
                    location="$LOCATION" \
                    webAppName="$WEB_APP_NAME" \
        --name "$DEPLOYMENT_NAME"
    
    print_success "Infrastructure deployment completed"
}

# Get deployment outputs
get_outputs() {
    print_header "Deployment Results"
    
    # Get outputs from deployment
    WEB_APP_URL=$(az deployment sub show \
        --name "$DEPLOYMENT_NAME" \
        --query properties.outputs.webAppUrl.value \
        --output tsv)
    
    ACTUAL_WEB_APP_NAME=$(az deployment sub show \
        --name "$DEPLOYMENT_NAME" \
        --query properties.outputs.webAppName.value \
        --output tsv)
    
    ACTUAL_RG_NAME=$(az deployment sub show \
        --name "$DEPLOYMENT_NAME" \
        --query properties.outputs.resourceGroupName.value \
        --output tsv)
    
    print_success "Deployment completed successfully!"
    echo ""
    print_info "Deployment Details:"
    echo "  🌐 Web App URL: $WEB_APP_URL"
    echo "  📱 Web App Name: $ACTUAL_WEB_APP_NAME"
    echo "  📦 Resource Group: $ACTUAL_RG_NAME"
    echo "  🕒 Deployment Name: $DEPLOYMENT_NAME"
    echo ""
    print_info "Next Steps:"
    echo "  1. Build and publish your .NET application"
    echo "  2. Deploy your application using:"
    echo "     az webapp deployment source config-zip \\"
    echo "       --resource-group \"$ACTUAL_RG_NAME\" \\"
    echo "       --name \"$ACTUAL_WEB_APP_NAME\" \\"
    echo "       --src \"./publish.zip\""
    echo ""
    print_info "To clean up resources later:"
    echo "  az group delete --name \"$ACTUAL_RG_NAME\" --yes --no-wait"
}

# Main execution
main() {
    print_header "Azure Infrastructure Deployment"
    echo "This script will deploy infrastructure for hosting a .NET application on Azure"
    echo ""
    
    # Ask for confirmation
    read -p "Do you want to proceed with deployment? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Deployment cancelled"
        exit 0
    fi
    
    check_prerequisites
    validate_templates
    deploy_infrastructure
    get_outputs
    
    print_success "🎉 All done! Your infrastructure is ready for deployment."
}

# Run the script
main "$@"