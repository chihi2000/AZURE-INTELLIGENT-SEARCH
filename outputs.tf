output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.intelligent_search.name
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.images.name
}

output "storage_container_name" {
  description = "Name of the blob container"
  value       = azurerm_storage_container.images.name
}

output "search_service_name" {
  description = "Name of the Azure AI Search service"
  value       = azurerm_search_service.intelligent_search.name
}

output "search_service_endpoint" {
  description = "Endpoint URL for the Azure AI Search service"
  value       = "https://${azurerm_search_service.intelligent_search.name}.search.windows.net"
}

output "cognitive_services_endpoint" {
  description = "Endpoint for Cognitive Services"
  value       = azurerm_cognitive_account.vision.endpoint
}

output "instructions" {
  description = "Next steps to use the intelligent search solution"
  value       = <<-EOT

    Deployment Complete!

    Next Steps:
    1. Upload images to the storage container:
       Container: ${azurerm_storage_container.images.name}
       Storage Account: ${azurerm_storage_account.images.name}

    2. Run the indexer to process images:
       az search indexer run --name image-indexer --service-name ${azurerm_search_service.intelligent_search.name} --resource-group ${azurerm_resource_group.intelligent_search.name}

    3. Query your intelligent search index:
       Search Explorer: ${azurerm_search_service.intelligent_search.name} -> Search Explorer
       Or use the REST API: https://${azurerm_search_service.intelligent_search.name}.search.windows.net/indexes/image-index/docs/search?api-version=2023-11-01

    4. To upload sample images via Azure CLI:
       az storage blob upload-batch --account-name ${azurerm_storage_account.images.name} --destination ${azurerm_storage_container.images.name} --source ./images/
  EOT
}
