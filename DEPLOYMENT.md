# Deployment Guide

This guide provides detailed instructions for deploying the SWOO Azure infrastructure.

## Table of Contents
- [Quick Start](#quick-start)
- [Prerequisites](#prerequisites)
- [Deployment Options](#deployment-options)
- [Step-by-Step Deployment](#step-by-step-deployment)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Rollback](#rollback)

## Quick Start

For experienced users with Azure CLI and prerequisites already set up:

```bash
# Login and set subscription
az login
az account set --subscription "your-subscription-id"

# Deploy using the script
./deploy.sh deploy
```

## Prerequisites

### Required Tools
1. **Azure CLI** (version 2.20.0 or later)
   - Install: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
   - Verify: `az --version`

2. **Bicep CLI** (included with Azure CLI 2.20.0+)
   - Verify: `bicep --version`
   - If needed: `az bicep install`

3. **Bash Shell** (for deployment script)
   - Linux/macOS: Built-in
   - Windows: Use Git Bash, WSL, or Azure Cloud Shell

### Azure Requirements
- Active Azure subscription
- Permissions to create resources in the subscription
- Resource Provider registrations:
  - Microsoft.Network
  - Microsoft.Storage
  - Microsoft.OperationalInsights

### Register Resource Providers (if needed)
```bash
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.OperationalInsights
```

## Deployment Options

### Option 1: Using the Deployment Script (Recommended)

The `deploy.sh` script automates the entire deployment process.

**Available Commands:**
```bash
./deploy.sh validate        # Validate templates only
./deploy.sh what-if         # Preview changes
./deploy.sh deploy          # Deploy everything
./deploy.sh deploy-main     # Deploy VNet and networking only
./deploy.sh deploy-storage  # Deploy storage only
```

**Example:**
```bash
# Validate before deploying
./deploy.sh validate

# Preview changes
./deploy.sh what-if

# Deploy all infrastructure
./deploy.sh deploy
```

### Option 2: Manual Deployment with Azure CLI

#### Step 1: Login to Azure
```bash
az login
```

#### Step 2: Select Subscription
```bash
# List subscriptions
az account list --output table

# Set active subscription
az account set --subscription "your-subscription-id"
```

#### Step 3: Create Resource Group
```bash
az group create \
  --name rg-swoo-prod-uks \
  --location uksouth
```

#### Step 4: Validate Templates
```bash
# Validate main template
az deployment group validate \
  --resource-group rg-swoo-prod-uks \
  --template-file Main.bicep \
  --parameters Main.parameters.json

# Validate storage template
az deployment group validate \
  --resource-group rg-swoo-prod-uks \
  --template-file storage.bicep \
  --parameters storage.parameters.json
```

#### Step 5: Deploy Infrastructure
```bash
# Deploy main infrastructure
az deployment group create \
  --resource-group rg-swoo-prod-uks \
  --template-file Main.bicep \
  --parameters Main.parameters.json \
  --name main-deployment

# Deploy storage
az deployment group create \
  --resource-group rg-swoo-prod-uks \
  --template-file storage.bicep \
  --parameters storage.parameters.json \
  --name storage-deployment
```

### Option 3: Azure Portal Deployment

1. Navigate to the [Azure Portal](https://portal.azure.com)
2. Search for "Deploy a custom template"
3. Click "Build your own template in the editor"
4. Copy the contents of `Main.bicep` (or build it to JSON first)
5. Click "Save"
6. Fill in the parameters
7. Click "Review + create" then "Create"

## Step-by-Step Deployment

### 1. Prepare Environment

```bash
# Clone or navigate to the repository
cd /path/to/swoo

# Verify files exist
ls -la *.bicep *.parameters.json

# Build Bicep templates to review ARM JSON (optional)
bicep build Main.bicep
bicep build storage.bicep
```

### 2. Customize Parameters

Edit parameter files for your environment:

**Main.parameters.json** - Network infrastructure
```json
{
  "environment": { "value": "prod" },
  "location": { "value": "uksouth" },
  "vnetAddressPrefix": { "value": "10.150.0.0/22" },
  "tags": {
    "value": {
      "Environment": "prod",
      "ManagedBy": "Bicep",
      "Project": "swoo",
      "Owner": "Your Team Name"
    }
  }
}
```

**storage.parameters.json** - Storage account
```json
{
  "storageAccountName": { "value": "swooproduksstorage" },
  "location": { "value": "uksouth" },
  "skuName": { "value": "Standard_LRS" }
}
```

### 3. Run What-If Analysis

Before deploying, preview the changes:

```bash
az deployment group what-if \
  --resource-group rg-swoo-prod-uks \
  --template-file Main.bicep \
  --parameters Main.parameters.json
```

Review the output carefully:
- ✓ Green = Resource will be created
- ~ Yellow = Resource will be modified
- - Red = Resource will be deleted

### 4. Deploy

```bash
# Deploy using script
./deploy.sh deploy

# OR deploy manually
az deployment group create \
  --resource-group rg-swoo-prod-uks \
  --template-file Main.bicep \
  --parameters Main.parameters.json
```

### 5. Monitor Deployment

```bash
# Watch deployment status
az deployment group show \
  --resource-group rg-swoo-prod-uks \
  --name main-deployment \
  --query "properties.provisioningState"

# View deployment outputs
az deployment group show \
  --resource-group rg-swoo-prod-uks \
  --name main-deployment \
  --query "properties.outputs"
```

## Verification

### 1. Check Resource Group

```bash
az group show --name rg-swoo-prod-uks --output table
```

### 2. List Deployed Resources

```bash
az resource list \
  --resource-group rg-swoo-prod-uks \
  --output table
```

### 3. Verify Virtual Network

```bash
az network vnet show \
  --resource-group rg-swoo-prod-uks \
  --name prodswoo-vnet-uksouth \
  --output table

# List subnets
az network vnet subnet list \
  --resource-group rg-swoo-prod-uks \
  --vnet-name prodswoo-vnet-uksouth \
  --output table
```

### 4. Verify Storage Account

```bash
az storage account show \
  --name swooproduksstorage \
  --resource-group rg-swoo-prod-uks \
  --output table
```

### 5. Check Log Analytics

```bash
az monitor log-analytics workspace show \
  --resource-group rg-swoo-prod-uks \
  --workspace-name prodswoo-law-uksouth \
  --output table
```

## Troubleshooting

### Common Issues

#### Issue: Template Validation Fails
```bash
# Solution: Review error message and check template syntax
bicep build Main.bicep
```

#### Issue: Resource Already Exists
```bash
# Solution: Delete existing resource or use different name
az resource delete --ids <resource-id>
```

#### Issue: Insufficient Permissions
```bash
# Solution: Check your role assignments
az role assignment list --assignee your-email@domain.com
```

#### Issue: Quota Exceeded
```bash
# Solution: Request quota increase or use different region
az vm list-usage --location uksouth --output table
```

### View Deployment Errors

```bash
# Get deployment error details
az deployment group show \
  --resource-group rg-swoo-prod-uks \
  --name main-deployment \
  --query "properties.error"

# View deployment operations
az deployment operation group list \
  --resource-group rg-swoo-prod-uks \
  --name main-deployment
```

### Enable Debug Logging

```bash
az deployment group create \
  --resource-group rg-swoo-prod-uks \
  --template-file Main.bicep \
  --parameters Main.parameters.json \
  --debug
```

## Rollback

### Delete Specific Deployment

```bash
# Note: This doesn't delete resources, only deployment history
az deployment group delete \
  --resource-group rg-swoo-prod-uks \
  --name main-deployment
```

### Delete Resources

```bash
# Delete specific resource
az network vnet delete \
  --resource-group rg-swoo-prod-uks \
  --name prodswoo-vnet-uksouth

# Delete entire resource group (CAUTION!)
az group delete \
  --name rg-swoo-prod-uks \
  --yes --no-wait
```

### Redeploy Previous Version

```bash
# Revert to previous template version in git
git checkout HEAD~1 Main.bicep

# Deploy the previous version
./deploy.sh deploy
```

## Best Practices

1. **Always validate before deploying**
   ```bash
   ./deploy.sh validate
   ```

2. **Use what-if to preview changes**
   ```bash
   ./deploy.sh what-if
   ```

3. **Deploy to test environment first**
   - Create separate parameter files for dev/test/prod
   - Test in non-production first

4. **Keep deployment history**
   - Don't delete deployment history unless necessary
   - Review previous deployments for troubleshooting

5. **Use tags consistently**
   - Tag all resources for cost tracking
   - Include environment, owner, project tags

6. **Monitor deployments**
   - Watch for warnings and errors
   - Review deployment outputs

7. **Document changes**
   - Update README when making infrastructure changes
   - Keep parameter files in version control

## Next Steps

After successful deployment:

1. **Configure Monitoring**
   - Set up diagnostic settings
   - Create Azure Monitor alerts
   - Configure Log Analytics queries

2. **Implement Security**
   - Review NSG rules
   - Configure Azure Policy
   - Enable Azure Security Center

3. **Set Up Governance**
   - Apply resource locks
   - Configure RBAC
   - Implement Azure Blueprints

4. **Cost Management**
   - Set up budgets and alerts
   - Review cost optimization recommendations
   - Tag resources for cost allocation

## Support

For issues or questions:
- Review this guide
- Check Azure documentation
- Contact the infrastructure team
