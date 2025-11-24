#!/bin/bash

# Azure Infrastructure Deployment Script
# This script deploys the SWOO Azure infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
RESOURCE_GROUP="rg-swoo-prod-uks"
LOCATION="uksouth"
SUBSCRIPTION_ID=""

# Functions
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check if Azure CLI is installed
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if Bicep is installed
    if ! command -v bicep &> /dev/null; then
        print_error "Bicep CLI is not installed. Please install it first."
        exit 1
    fi
    
    print_info "Prerequisites check passed!"
}

login_azure() {
    print_info "Checking Azure login status..."
    
    if ! az account show &> /dev/null; then
        print_warning "Not logged in to Azure. Initiating login..."
        az login
    else
        print_info "Already logged in to Azure"
    fi
}

set_subscription() {
    if [ -z "$SUBSCRIPTION_ID" ]; then
        print_info "Current subscription:"
        az account show --query "[name, id]" -o table
    else
        print_info "Setting subscription to: $SUBSCRIPTION_ID"
        az account set --subscription "$SUBSCRIPTION_ID"
    fi
}

create_resource_group() {
    print_info "Creating resource group: $RESOURCE_GROUP in $LOCATION..."
    
    if az group exists --name "$RESOURCE_GROUP" | grep -q true; then
        print_warning "Resource group already exists"
    else
        az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
        print_info "Resource group created successfully"
    fi
}

validate_templates() {
    print_info "Validating Bicep templates..."
    
    # Validate Main.bicep
    print_info "Validating Main.bicep..."
    az deployment group validate \
        --resource-group "$RESOURCE_GROUP" \
        --template-file Main.bicep \
        --parameters Main.parameters.json \
        --query "properties.provisioningState" -o tsv
    
    # Validate storage.bicep
    print_info "Validating storage.bicep..."
    az deployment group validate \
        --resource-group "$RESOURCE_GROUP" \
        --template-file storage.bicep \
        --parameters storage.parameters.json \
        --query "properties.provisioningState" -o tsv
    
    print_info "Validation completed successfully!"
}

deploy_infrastructure() {
    print_info "Deploying main infrastructure (VNet, NSG, Log Analytics)..."
    
    az deployment group create \
        --resource-group "$RESOURCE_GROUP" \
        --template-file Main.bicep \
        --parameters Main.parameters.json \
        --name "main-deployment-$(date +%Y%m%d-%H%M%S)"
    
    print_info "Main infrastructure deployed successfully!"
}

deploy_storage() {
    print_info "Deploying storage account..."
    
    az deployment group create \
        --resource-group "$RESOURCE_GROUP" \
        --template-file storage.bicep \
        --parameters storage.parameters.json \
        --name "storage-deployment-$(date +%Y%m%d-%H%M%S)"
    
    print_info "Storage account deployed successfully!"
}

what_if_analysis() {
    print_info "Running what-if analysis for Main.bicep..."
    
    az deployment group what-if \
        --resource-group "$RESOURCE_GROUP" \
        --template-file Main.bicep \
        --parameters Main.parameters.json
}

# Main execution
main() {
    echo "========================================"
    echo "  Azure Infrastructure Deployment"
    echo "========================================"
    echo ""
    
    # Parse command line arguments
    case "${1:-}" in
        validate)
            check_prerequisites
            login_azure
            set_subscription
            create_resource_group
            validate_templates
            ;;
        what-if)
            check_prerequisites
            login_azure
            set_subscription
            create_resource_group
            what_if_analysis
            ;;
        deploy)
            check_prerequisites
            login_azure
            set_subscription
            create_resource_group
            validate_templates
            deploy_infrastructure
            deploy_storage
            print_info "Deployment completed successfully!"
            ;;
        deploy-main)
            check_prerequisites
            login_azure
            set_subscription
            create_resource_group
            deploy_infrastructure
            ;;
        deploy-storage)
            check_prerequisites
            login_azure
            set_subscription
            create_resource_group
            deploy_storage
            ;;
        *)
            echo "Usage: $0 {validate|what-if|deploy|deploy-main|deploy-storage}"
            echo ""
            echo "Commands:"
            echo "  validate        - Validate all Bicep templates"
            echo "  what-if         - Show what changes will be made"
            echo "  deploy          - Deploy all infrastructure"
            echo "  deploy-main     - Deploy only main infrastructure (VNet, NSG, etc.)"
            echo "  deploy-storage  - Deploy only storage account"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
