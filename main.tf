terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "intelligent_search" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}

# storage Account for Image Assets
resource "azurerm_storage_account" "images" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.intelligent_search.name
  location                 = azurerm_resource_group.intelligent_search.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  blob_properties {
    cors_rule {
      allowed_headers    = ["*"]
      allowed_methods    = ["GET", "HEAD"]
      allowed_origins    = ["*"]
      exposed_headers    = ["*"]
      max_age_in_seconds = 3600
    }
  }

  tags = var.tags
}

# Blob Container for Images
resource "azurerm_storage_container" "images" {
  name                  = "image-assets"
  storage_account_id    = azurerm_storage_account.images.id
  container_access_type = "private"
}

# Cognitive Services Account for AI Vision
resource "azurerm_cognitive_account" "vision" {
  name                = var.cognitive_account_name
  resource_group_name = azurerm_resource_group.intelligent_search.name
  location            = azurerm_resource_group.intelligent_search.location
  kind                = "CognitiveServices"
  sku_name            = "S0"

  tags = var.tags
}

# Azure AI Search Service
resource "azurerm_search_service" "intelligent_search" {
  name                = var.search_service_name
  resource_group_name = azurerm_resource_group.intelligent_search.name
  location            = azurerm_resource_group.intelligent_search.location
  sku                 = "basic"
  replica_count       = 1
  partition_count     = 1

  tags = var.tags
}

# Data Source Configuration
resource "null_resource" "search_datasource" {
  depends_on = [
    azurerm_search_service.intelligent_search,
    azurerm_storage_container.images
  ]

  provisioner "local-exec" {
    command = <<-EOT
      curl -X POST "https://${azurerm_search_service.intelligent_search.name}.search.windows.net/datasources?api-version=2023-11-01" \
        -H "Content-Type: application/json" \
        -H "api-key: ${azurerm_search_service.intelligent_search.primary_key}" \
        -d '{
          "name": "image-datasource",
          "type": "azureblob",
          "credentials": {
            "connectionString": "${azurerm_storage_account.images.primary_connection_string}"
          },
          "container": {
            "name": "image-assets"
          }
        }'
    EOT
  }
}

# Skillset for AI Vision Processing
resource "null_resource" "search_skillset" {
  depends_on = [null_resource.search_datasource]

  provisioner "local-exec" {
    command = <<-EOT
      curl -X POST "https://${azurerm_search_service.intelligent_search.name}.search.windows.net/skillsets?api-version=2023-11-01" \
        -H "Content-Type: application/json" \
        -H "api-key: ${azurerm_search_service.intelligent_search.primary_key}" \
        -d '{
          "name": "vision-skillset",
          "description": "Extract image insights using Azure AI Vision",
          "skills": [
            {
              "@odata.type": "#Microsoft.Skills.Vision.OcrSkill",
              "context": "/document/normalized_images/*",
              "detectOrientation": true,
              "outputs": [
                {
                  "name": "text",
                  "targetName": "extractedText"
                }
              ]
            },
            {
              "@odata.type": "#Microsoft.Skills.Vision.ImageAnalysisSkill",
              "context": "/document/normalized_images/*",
              "visualFeatures": ["tags", "description"],
              "outputs": [
                {
                  "name": "tags",
                  "targetName": "imageTags"
                },
                {
                  "name": "description",
                  "targetName": "imageDescription"
                }
              ]
            }
          ],
          "cognitiveServices": {
            "@odata.type": "#Microsoft.Azure.Search.CognitiveServicesByKey",
            "key": "${azurerm_cognitive_account.vision.primary_access_key}"
          }
        }'
    EOT
  }
}

# Index Definition
resource "null_resource" "search_index" {
  depends_on = [azurerm_search_service.intelligent_search]

  provisioner "local-exec" {
    command = <<-EOT
      curl -X POST "https://${azurerm_search_service.intelligent_search.name}.search.windows.net/indexes?api-version=2023-11-01" \
        -H "Content-Type: application/json" \
        -H "api-key: ${azurerm_search_service.intelligent_search.primary_key}" \
        -d '{
          "name": "image-index",
          "fields": [
            {
              "name": "id",
              "type": "Edm.String",
              "key": true,
              "searchable": false
            },
            {
              "name": "metadata_storage_name",
              "type": "Edm.String",
              "searchable": true,
              "filterable": true,
              "sortable": true
            },
            {
              "name": "metadata_storage_path",
              "type": "Edm.String",
              "searchable": false,
              "filterable": false
            },
            {
              "name": "extractedText",
              "type": "Collection(Edm.String)",
              "searchable": true
            },
            {
              "name": "imageTags",
              "type": "Collection(Edm.String)",
              "searchable": true,
              "filterable": true
            },
            {
              "name": "imageCaption",
              "type": "Edm.String",
              "searchable": true
            }
          ]
        }'
    EOT
  }
}

# Indexer
resource "null_resource" "search_indexer" {
  depends_on = [
    null_resource.search_datasource,
    null_resource.search_skillset,
    null_resource.search_index
  ]

  provisioner "local-exec" {
    command = <<-EOT
      curl -X POST "https://${azurerm_search_service.intelligent_search.name}.search.windows.net/indexers?api-version=2023-11-01" \
        -H "Content-Type: application/json" \
        -H "api-key: ${azurerm_search_service.intelligent_search.primary_key}" \
        -d '{
          "name": "image-indexer",
          "dataSourceName": "image-datasource",
          "targetIndexName": "image-index",
          "skillsetName": "vision-skillset",
          "parameters": {
            "configuration": {
              "imageAction": "generateNormalizedImages"
            }
          },
          "fieldMappings": [
            {
              "sourceFieldName": "metadata_storage_path",
              "targetFieldName": "id",
              "mappingFunction": {
                "name": "base64Encode"
              }
            },
            {
              "sourceFieldName": "metadata_storage_name",
              "targetFieldName": "metadata_storage_name"
            }
          ],
          "outputFieldMappings": [
            {
              "sourceFieldName": "/document/normalized_images/*/extractedText",
              "targetFieldName": "extractedText"
            },
            {
              "sourceFieldName": "/document/normalized_images/*/imageTags/*/name",
              "targetFieldName": "imageTags"
            },
            {
              "sourceFieldName": "/document/normalized_images/*/imageDescription/captions/*/text",
              "targetFieldName": "imageCaption"
            }
          ]
        }'
    EOT
  }
}
