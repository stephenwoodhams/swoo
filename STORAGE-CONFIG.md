# Storage Account Configuration

This file documents the available parameters for storage.bicep.

## Basic Parameters

```json
{
  "storageAccountName": { "value": "swooproduksstorage" },
  "location": { "value": "uksouth" },
  "skuName": { "value": "Standard_LRS" },
  "kind": { "value": "StorageV2" },
  "accessTier": { "value": "Hot" }
}
```

## Enhanced Security Configuration

For production environments requiring higher security, add these parameters:

```json
{
  "publicNetworkAccess": { "value": "Disabled" },
  "allowSharedKeyAccess": { "value": false }
}
```

**Notes:**
- `publicNetworkAccess: "Disabled"` requires private endpoints for access
- `allowSharedKeyAccess: false` requires Azure AD authentication (no connection strings)
- These settings provide defense-in-depth for sensitive data

## Available SKUs

- `Standard_LRS` - Locally redundant storage (default, lowest cost)
- `Standard_GRS` - Geo-redundant storage (DR capability)
- `Standard_RAGRS` - Read-access geo-redundant storage
- `Standard_ZRS` - Zone-redundant storage (HA within region)
- `Premium_LRS` - Premium SSD storage
- `Premium_ZRS` - Premium zone-redundant

## Access Tiers

- `Hot` - Optimized for frequent access (default)
- `Cool` - Optimized for infrequent access (lower storage cost, higher access cost)

## Example: High Security Configuration

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "storageAccountName": { "value": "swooproduksstorage" },
    "location": { "value": "uksouth" },
    "skuName": { "value": "Standard_ZRS" },
    "kind": { "value": "StorageV2" },
    "accessTier": { "value": "Hot" },
    "publicNetworkAccess": { "value": "Disabled" },
    "allowSharedKeyAccess": { "value": false },
    "tags": {
      "value": {
        "Environment": "prod",
        "ManagedBy": "Bicep",
        "Project": "swoo",
        "SecurityLevel": "High"
      }
    }
  }
}
```

## Example: DR-Enabled Configuration

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "storageAccountName": { "value": "swooproduksstorage" },
    "location": { "value": "uksouth" },
    "skuName": { "value": "Standard_GRS" },
    "kind": { "value": "StorageV2" },
    "accessTier": { "value": "Hot" },
    "tags": {
      "value": {
        "Environment": "prod",
        "ManagedBy": "Bicep",
        "Project": "swoo",
        "DR": "Enabled"
      }
    }
  }
}
```
