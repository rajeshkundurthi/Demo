locals {
  resource_groups = csvdecode(file("${path.module}/resource_groups.txt"))
}

resource "azurerm_resource_group" "rg" {
  for_each = {
    for rg in local.resource_groups : trimspace(rg.rg_name) => rg
  }

  name     = trimspace(each.value.rg_name)
  location = trimspace(each.value.location)

  tags = {
    Environment = trimspace(each.value.environment)
    Owner       = "Satish"
  }
}

output "rg_names" {
  value = [for rg in azurerm_resource_group.rg : rg.name]
}