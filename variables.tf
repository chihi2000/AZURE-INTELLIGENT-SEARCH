variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-intelligent-search"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "storage_account_name" {
  description = "Name of the storage account (must be globally unique)"
  type        = string
  default     = "stintsearch"

  validation {
    condition     = length(var.storage_account_name) >= 3 && length(var.storage_account_name) <= 24
    error_message = "Storage account name must be between 3 and 24 characters."
  }
}

variable "cognitive_account_name" {
  description = "Name of the Cognitive Services account"
  type        = string
  default     = "cog-vision-search"
}

variable "search_service_name" {
  description = "Name of the Azure AI Search service (must be globally unique)"
  type        = string
  default     = "srch-intelligent-search"

  validation {
    condition     = length(var.search_service_name) >= 2 && length(var.search_service_name) <= 60
    error_message = "Search service name must be between 2 and 60 characters."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Production"
    Project     = "Intelligent-Image-Search"
    ManagedBy   = "Terraform"
  }
}
