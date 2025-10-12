# Azure Intelligent Image Search

AI-powered image search using Azure AI Search and Azure AI Vision. Automatically analyzes, tags, and makes images searchable.

## What It Does

- Extracts text from images (OCR)
- Generates image tags and captions
- Makes images searchable by content
- Fully automated with Terraform

## Quick Start

```bash
# Deploy
terraform init
terraform apply

# Upload images
az storage blob upload-batch \
  --account-name <storage-account-name> \
  --destination image-assets \
  --source ./images/

# Run indexer
az search indexer run \
  --name image-indexer \
  --service-name <search-service-name> \
  --resource-group <resource-group-name>
```

## Prerequisites

- Azure subscription
- Terraform >= 1.0
- Azure CLI

## Configuration

Edit `variables.tf` or create `terraform.tfvars`:

```hcl
storage_account_name  = "youruniquename123"  # Must be globally unique
search_service_name   = "your-search-name"   # Must be globally unique
location              = "eastus"
```

## Resources Created

- Storage Account + Blob Container
- Azure AI Search Service
- Cognitive Services (AI Vision)
- Search datasource, skillset, index, and indexer

## Cost

Approximately $80-100/month for moderate usage.

## Cleanup

```bash
terraform destroy
```

## License

MIT
