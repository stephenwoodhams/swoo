# Azure Infrastructure as Code - SWOO Project

This repository contains Azure infrastructure code using Bicep and ARM templates for the SWOO project.

## Overview

This infrastructure deploys a comprehensive Azure environment including:
- Virtual Network with multiple subnets
- Network Security Groups with security rules
- Log Analytics Workspace for monitoring
- Storage Account for data persistence

## Architecture

### Network Design
- **Virtual Network**: 10.150.0.0/22 address space in UK South region
- **Subnets**:
  - `GatewaySubnet`: 10.150.3.240/28 - For VPN/ExpressRoute gateways
  - `swoo-sub-ds-uks`: 10.150.3.192/28 - Domain Services subnet
  - `swoo-sub-avd-uks`: 10.150.3.96/27 - Azure Virtual Desktop subnet
  - `swoo-sub-sql-uks`: 10.150.2.64/26 - SQL Server subnet

### Security
- Network Security Groups applied to application subnets
- HTTPS (443) and RDP (3389 from VNet only) allowed
- Log Analytics for monitoring and compliance

## Prerequisites

- Azure CLI installed ([Install Guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli))
- Bicep CLI installed (comes with Azure CLI 2.20.0+)
- An active Azure subscription
- Appropriate permissions to create resources

## File Structure

```
.
├── Main.bicep                 # Main infrastructure template (VNet, NSG, Log Analytics)
├── Main.parameters.json       # Parameters for main template
├── storage.bicep              # Storage account template
├── storage.parameters.json    # Parameters for storage template
├── template.json              # Legacy ARM template (for reference)
├── parameters.json            # Legacy parameters (for reference)
├── deploy.sh                  # Deployment automation script
├── DEPLOYMENT.md              # Detailed deployment guide
├── ARCHITECTURE.md            # Architecture documentation
└── README.md                  # This file
```

## Deployment

### Using Azure CLI

1. **Login to Azure**:
   ```bash
   az login
   ```

2. **Set your subscription**:
   ```bash
   az account set --subscription "your-subscription-id"
   ```

3. **Create a resource group** (if not exists):
   ```bash
   az group create --name rg-swoo-prod-uks --location uksouth
   ```

4. **Deploy the main infrastructure**:
   ```bash
   az deployment group create \
     --resource-group rg-swoo-prod-uks \
     --template-file Main.bicep \
     --parameters Main.parameters.json
   ```

5. **Deploy the storage account** (optional):
   ```bash
   az deployment group create \
     --resource-group rg-swoo-prod-uks \
     --template-file storage.bicep \
     --parameters storage.parameters.json
   ```

   Or use the legacy ARM template:
   ```bash
   az deployment group create \
     --resource-group rg-swoo-prod-uks \
     --template-file template.json \
     --parameters parameters.json
   ```

### Validate Before Deployment

```bash
# Validate Main.bicep
az deployment group validate \
  --resource-group rg-swoo-prod-uks \
  --template-file Main.bicep \
  --parameters Main.parameters.json

# Build Bicep to review generated ARM template
bicep build Main.bicep
```

## Parameters

### Main.bicep Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `environment` | string | 'prod' | Environment prefix (dev/test/prod) |
| `location` | string | 'uksouth' | Azure region for resources |
| `vnetAddressPrefix` | string | '10.150.0.0/22' | Virtual network address space |
| `tags` | object | See file | Tags to apply to resources |

### Customization

To deploy to different environments, update the parameters:

**Development Environment**:
```json
{
  "environment": { "value": "dev" },
  "location": { "value": "uksouth" },
  "vnetAddressPrefix": { "value": "10.151.0.0/22" }
}
```

**Test Environment**:
```json
{
  "environment": { "value": "test" },
  "location": { "value": "uksouth" },
  "vnetAddressPrefix": { "value": "10.152.0.0/22" }
}
```

## Outputs

The deployment provides the following outputs:
- `vnetId`: Resource ID of the virtual network
- `vnetName`: Name of the virtual network
- `logAnalyticsWorkspaceId`: Resource ID of Log Analytics workspace
- `nsgId`: Resource ID of the network security group

## Best Practices

1. **Always validate** templates before deployment
2. **Use parameter files** for different environments
3. **Review changes** with what-if before deploying:
   ```bash
   az deployment group what-if \
     --resource-group rg-swoo-prod-uks \
     --template-file Main.bicep \
     --parameters Main.parameters.json
   ```
4. **Tag resources** appropriately for cost management
5. **Use Key Vault** for secrets (not implemented in this version)

## Security Considerations

- Network Security Groups restrict traffic to application subnets
- Storage accounts use TLS 1.2 minimum and HTTPS-only traffic
- Blob public access is disabled by default
- For enhanced security, configure storage accounts with:
  - `publicNetworkAccess: 'Disabled'` and private endpoints
  - `allowSharedKeyAccess: false` (requires Azure AD authentication)
- Consider implementing Azure Policy for compliance
- Enable Azure Security Center for threat protection
- Review NSG rules regularly and apply principle of least privilege
- Use Azure Bastion for secure RDP access instead of exposing RDP to VNet

## Monitoring

- Log Analytics Workspace is deployed for centralized logging
- Configure diagnostic settings on resources to send logs to Log Analytics
- Use Azure Monitor to create alerts and dashboards

## Maintenance

### Updating Infrastructure

1. Modify the Bicep template
2. Validate changes with `bicep build`
3. Review with `az deployment group what-if`
4. Deploy updates with `az deployment group create`

### Cleaning Up

To remove all deployed resources:
```bash
az group delete --name rg-swoo-prod-uks --yes --no-wait
```

## Contributing

1. Create a feature branch
2. Make changes to Bicep templates
3. Validate and test deployments
4. Submit pull request

## License

This project is for internal use.

## Support

For issues or questions, please contact the infrastructure team.