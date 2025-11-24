# Architecture Documentation

## Overview

This document describes the Azure infrastructure architecture for the SWOO project, deployed using Infrastructure as Code (Bicep templates).

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Azure Subscription                           │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │         Resource Group: rg-swoo-prod-uks                   │ │
│  │                                                            │ │
│  │  ┌──────────────────────────────────────────────────────┐ │ │
│  │  │  Virtual Network: prodswoo-vnet-uksouth              │ │ │
│  │  │  Address Space: 10.150.0.0/22                        │ │ │
│  │  │                                                       │ │ │
│  │  │  ┌─────────────────────────────────────────────┐    │ │ │
│  │  │  │ GatewaySubnet (10.150.3.240/28)             │    │ │ │
│  │  │  │ - VPN/ExpressRoute Gateway                  │    │ │ │
│  │  │  └─────────────────────────────────────────────┘    │ │ │
│  │  │                                                       │ │ │
│  │  │  ┌─────────────────────────────────────────────┐    │ │ │
│  │  │  │ swoo-sub-ds-uks (10.150.3.192/28)           │    │ │ │
│  │  │  │ - Domain Services                           │    │ │ │
│  │  │  │ - NSG: prodswoo-nsg-uksouth                 │    │ │ │
│  │  │  └─────────────────────────────────────────────┘    │ │ │
│  │  │                                                       │ │ │
│  │  │  ┌─────────────────────────────────────────────┐    │ │ │
│  │  │  │ swoo-sub-avd-uks (10.150.3.96/27)           │    │ │ │
│  │  │  │ - Azure Virtual Desktop                     │    │ │ │
│  │  │  │ - NSG: prodswoo-nsg-uksouth                 │    │ │ │
│  │  │  └─────────────────────────────────────────────┘    │ │ │
│  │  │                                                       │ │ │
│  │  │  ┌─────────────────────────────────────────────┐    │ │ │
│  │  │  │ swoo-sub-sql-uks (10.150.2.64/26)           │    │ │ │
│  │  │  │ - SQL Servers and Databases                 │    │ │ │
│  │  │  │ - NSG: prodswoo-nsg-uksouth                 │    │ │ │
│  │  │  └─────────────────────────────────────────────┘    │ │ │
│  │  │                                                       │ │ │
│  │  └──────────────────────────────────────────────────────┘ │ │
│  │                                                            │ │
│  │  ┌──────────────────────────────────────────────────────┐ │ │
│  │  │  Network Security Group: prodswoo-nsg-uksouth        │ │ │
│  │  │  - Allow HTTPS (443)                                 │ │ │
│  │  │  - Allow RDP (3389) from VNet only                   │ │ │
│  │  └──────────────────────────────────────────────────────┘ │ │
│  │                                                            │ │
│  │  ┌──────────────────────────────────────────────────────┐ │ │
│  │  │  Log Analytics: prodswoo-law-uksouth                 │ │ │
│  │  │  - Centralized logging and monitoring                │ │ │
│  │  │  - 30-day retention                                  │ │ │
│  │  └──────────────────────────────────────────────────────┘ │ │
│  │                                                            │ │
│  │  ┌──────────────────────────────────────────────────────┐ │ │
│  │  │  Storage Account: swooproduksstorage                 │ │ │
│  │  │  - StorageV2, Standard LRS                           │ │ │
│  │  │  - Hot tier, TLS 1.2 minimum                         │ │ │
│  │  └──────────────────────────────────────────────────────┘ │ │
│  │                                                            │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Network Architecture

### Address Space Planning

**Virtual Network: 10.150.0.0/22** (1,024 IP addresses)

| Subnet | CIDR | Usable IPs | Purpose |
|--------|------|------------|---------|
| GatewaySubnet | 10.150.3.240/28 | 11 | VPN/ExpressRoute Gateway |
| swoo-sub-ds-uks | 10.150.3.192/28 | 11 | Domain Services (AD DS) |
| swoo-sub-avd-uks | 10.150.3.96/27 | 27 | Azure Virtual Desktop hosts |
| swoo-sub-sql-uks | 10.150.2.64/26 | 59 | SQL Server instances |
| *Reserved* | 10.150.0.0/24 | ~250 | Future expansion |

### Subnet Design Rationale

1. **GatewaySubnet (10.150.3.240/28)**
   - Reserved for Azure VPN/ExpressRoute Gateway
   - Must be named exactly "GatewaySubnet"
   - /28 provides sufficient IPs for gateway redundancy
   - No NSG allowed on GatewaySubnet per Azure requirements

2. **Domain Services Subnet (10.150.3.192/28)**
   - Hosts Active Directory Domain Services
   - Small subnet for domain controllers (typically 2-3)
   - Protected by NSG
   - Critical for authentication and authorization

3. **Azure Virtual Desktop Subnet (10.150.3.96/27)**
   - Hosts AVD session hosts
   - /27 allows for ~30 VMs
   - Scalable for user demand
   - Protected by NSG with RDP restrictions

4. **SQL Subnet (10.150.2.64/26)**
   - Dedicated subnet for SQL Server instances
   - Larger subnet for database tier
   - Isolated from client traffic
   - Protected by NSG with restricted access

### Network Security

**NSG Rules Applied to Application Subnets:**

| Priority | Name | Direction | Access | Protocol | Port | Source | Destination |
|----------|------|-----------|--------|----------|------|--------|-------------|
| 100 | AllowHTTPS | Inbound | Allow | TCP | 443 | * | * |
| 110 | AllowRDP | Inbound | Allow | TCP | 3389 | VirtualNetwork | * |

**Security Considerations:**
- RDP restricted to VirtualNetwork only (not Internet)
- HTTPS allowed for application access
- Additional rules should be added based on specific requirements
- Consider implementing Azure Bastion for secure RDP access
- Use Just-In-Time (JIT) access for administrative tasks

## Components

### 1. Virtual Network

**Resource:** `Microsoft.Network/virtualNetworks`
**Name:** `prodswoo-vnet-uksouth`
**Purpose:** Core networking infrastructure

**Features:**
- Isolated network space in Azure
- Custom address space (10.150.0.0/22)
- Multiple subnets for different workload tiers
- Foundation for all deployed resources

**Dependencies:** None (foundational resource)

### 2. Network Security Group

**Resource:** `Microsoft.Network/networkSecurityGroups`
**Name:** `prodswoo-nsg-uksouth`
**Purpose:** Network-level security

**Features:**
- Stateful firewall rules
- Applied to application subnets
- Restricts inbound/outbound traffic
- Logging capabilities

**Dependencies:** None

**Associated Subnets:**
- swoo-sub-ds-uks
- swoo-sub-avd-uks
- swoo-sub-sql-uks

### 3. Log Analytics Workspace

**Resource:** `Microsoft.OperationalInsights/workspaces`
**Name:** `prodswoo-law-uksouth`
**Purpose:** Centralized logging and monitoring

**Features:**
- PerGB2018 pricing tier (pay-per-GB)
- 30-day data retention
- Query language (KQL) for log analysis
- Integration with Azure Monitor

**Use Cases:**
- Security monitoring
- Performance diagnostics
- Compliance auditing
- Cost analysis

**Dependencies:** None

### 4. Storage Account

**Resource:** `Microsoft.Storage/storageAccounts`
**Name:** `swooproduksstorage`
**Purpose:** Blob, file, table, and queue storage

**Features:**
- StorageV2 (general purpose v2)
- Standard LRS (locally redundant)
- Hot access tier
- TLS 1.2 minimum encryption
- HTTPS-only traffic
- Blob public access disabled

**Use Cases:**
- Application data storage
- Backup and archival
- Log file storage
- Static website hosting

**Dependencies:** None

## Security Architecture

### Defense in Depth

```
┌─────────────────────────────────────────────────────────────┐
│ Layer 1: Network Security                                    │
│ - Network Security Groups                                    │
│ - Subnet isolation                                           │
│ - Private networking                                         │
└─────────────────────────────────────────────────────────────┘
                           │
┌─────────────────────────────────────────────────────────────┐
│ Layer 2: Identity & Access                                   │
│ - Azure AD authentication                                    │
│ - RBAC for resource access                                   │
│ - Managed identities                                         │
└─────────────────────────────────────────────────────────────┘
                           │
┌─────────────────────────────────────────────────────────────┐
│ Layer 3: Data Protection                                     │
│ - TLS 1.2 minimum                                            │
│ - Encryption at rest                                         │
│ - Encryption in transit                                      │
└─────────────────────────────────────────────────────────────┘
                           │
┌─────────────────────────────────────────────────────────────┐
│ Layer 4: Monitoring & Logging                                │
│ - Log Analytics                                              │
│ - Azure Monitor                                              │
│ - Activity logs                                              │
└─────────────────────────────────────────────────────────────┘
```

### Security Best Practices Implemented

1. **Network Isolation**
   - Dedicated subnets per workload type
   - NSGs on all application subnets
   - No direct Internet exposure on internal subnets

2. **Encryption**
   - HTTPS-only for storage accounts
   - TLS 1.2 minimum requirement
   - Encryption at rest enabled by default

3. **Access Control**
   - Shared key access can be disabled
   - OAuth authentication supported
   - Azure RBAC for management

4. **Monitoring**
   - Log Analytics for centralized logging
   - Diagnostic settings capability
   - Audit logging enabled

### Recommended Additional Security Measures

1. **Azure Bastion**
   - Secure RDP/SSH without public IPs
   - Reduces attack surface

2. **Azure Firewall**
   - Centralized egress filtering
   - Threat intelligence integration

3. **Private Endpoints**
   - Private connectivity to PaaS services
   - No Internet exposure

4. **Azure Policy**
   - Enforce security standards
   - Compliance automation

5. **Azure Security Center**
   - Threat protection
   - Security recommendations
   - Compliance dashboard

## Monitoring & Operations

### Logging Strategy

**Log Analytics Workspace** collects:
- NSG flow logs
- Resource diagnostic logs
- Activity logs
- Application logs

**Recommended Queries:**

```kql
// Failed authentication attempts
AzureDiagnostics
| where Category == "NetworkSecurityGroupEvent"
| where Type_s == "block"
| summarize count() by SourceIP_s, DestinationIP_s

// Storage account access
StorageBlobLogs
| where TimeGenerated > ago(24h)
| summarize count() by AccountName, OperationName

// Resource changes
AzureActivity
| where OperationNameValue endswith "write"
| project TimeGenerated, Caller, ResourceGroup, ResourceId
```

### Monitoring Recommendations

1. **Set Up Alerts**
   - NSG rule violations
   - Unusual storage access patterns
   - Resource health issues
   - Budget thresholds

2. **Create Dashboards**
   - Network traffic overview
   - Security events
   - Cost analysis
   - Resource utilization

3. **Configure Diagnostic Settings**
   - Enable for all resources
   - Send to Log Analytics
   - Archive to storage for compliance

## Scalability

### Current Capacity

- **Virtual Network:** 1,024 IP addresses (expandable)
- **Subnets:** Can be resized (no resources attached)
- **Storage:** Unlimited (pay-per-use)
- **Log Analytics:** PerGB2018 (scales with usage)

### Scaling Considerations

1. **Horizontal Scaling**
   - Add more subnets for new workloads
   - Deploy resources across availability zones
   - Use VM scale sets for compute

2. **Vertical Scaling**
   - Expand subnet address ranges (requires recreation)
   - Upgrade storage account SKU
   - Increase Log Analytics retention

3. **Growth Planning**
   - Reserve 10.150.0.0/24 for future subnets
   - Plan for additional regions
   - Consider hub-spoke topology for multi-region

## Cost Optimization

### Current Costs (Estimated Monthly)

| Resource | Estimated Cost |
|----------|----------------|
| Virtual Network | $0 (no charge for VNet) |
| Network Security Group | $0 (no charge for NSG) |
| Log Analytics Workspace | ~$2-10 (depends on ingestion) |
| Storage Account (Standard LRS) | ~$20-50 (depends on usage) |
| **Total** | **~$22-60/month** |

### Cost Optimization Tips

1. **Storage**
   - Use appropriate access tiers (Hot/Cool/Archive)
   - Delete old blobs with lifecycle policies
   - Use cheaper SKUs for non-critical data

2. **Log Analytics**
   - Set appropriate retention (30 days default)
   - Archive old logs to storage
   - Use commitment tiers for predictable workloads

3. **Networking**
   - Minimize cross-region data transfer
   - Use Azure CDN for static content
   - Optimize outbound data transfer

## Compliance

### Supported Compliance Standards

- **ISO 27001**
- **SOC 2**
- **GDPR** (with proper configuration)
- **HIPAA** (with additional controls)

### Compliance Features

1. **Data Residency**
   - All resources in UK South region
   - Data stays in UK

2. **Audit Trails**
   - Activity logs for all changes
   - Resource logs in Log Analytics
   - 30-day retention (expandable)

3. **Encryption**
   - Data at rest encrypted
   - TLS 1.2 for data in transit

## Disaster Recovery

### Current State

- **RTO (Recovery Time Objective):** Not defined
- **RPO (Recovery Point Objective):** Not defined
- **Redundancy:** LRS (3 copies in single datacenter)

### DR Recommendations

1. **Backup Strategy**
   - Enable Azure Backup for VMs
   - Use GRS for storage accounts (geo-redundant)
   - Export ARM templates regularly

2. **High Availability**
   - Deploy across availability zones
   - Use zone-redundant storage (ZRS)
   - Implement load balancing

3. **Replication**
   - Set up VNet peering to secondary region
   - Enable geo-replication for storage
   - Use Traffic Manager for failover

## Future Enhancements

### Planned Additions

1. **Compute Resources**
   - Azure Virtual Machines
   - Azure Virtual Desktop session hosts
   - SQL Server instances

2. **Security**
   - Azure Bastion for secure access
   - Azure Firewall for egress filtering
   - Private endpoints for PaaS services

3. **Monitoring**
   - Azure Monitor alerts
   - Application Insights
   - Network Watcher

4. **Automation**
   - CI/CD pipeline for deployments
   - Azure Automation runbooks
   - Auto-scaling rules

### Modularization

Consider breaking down into modules:
- `modules/network.bicep`
- `modules/storage.bicep`
- `modules/monitoring.bicep`
- `modules/security.bicep`

## References

- [Azure Bicep Documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Azure Virtual Network Documentation](https://docs.microsoft.com/en-us/azure/virtual-network/)
- [Azure Storage Documentation](https://docs.microsoft.com/en-us/azure/storage/)
- [Log Analytics Documentation](https://docs.microsoft.com/en-us/azure/azure-monitor/logs/)
- [NSG Documentation](https://docs.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview)
