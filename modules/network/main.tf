variable "network_data" {}
variable "rg_map" {}

# VNET
resource "azurerm_virtual_network" "vnet" {
  for_each = {
    for v in var.network_data :
    "${v.rg_name}-${v.vnet_name}" => v
  }

  name                = each.value.vnet_name
  location            = var.rg_map[each.value.rg_name].location
  resource_group_name = var.rg_map[each.value.rg_name].name
  address_space       = [each.value.address_space]
}

# SUBNET
resource "azurerm_subnet" "subnet" {
  for_each = {
    for s in var.network_data :
    s.subnet_name => s
  }

  name                 = each.value.subnet_name
  resource_group_name  = var.rg_map[each.value.rg_name].name
  virtual_network_name = azurerm_virtual_network.vnet[
    "${each.value.rg_name}-${each.value.vnet_name}"
  ].name

  address_prefixes = [each.value.subnet_prefix]
}

# NSG
resource "azurerm_network_security_group" "nsg" {
  for_each = {
    for s in var.network_data :
    s.nsg_name => s
  }

  name                = each.value.nsg_name
  location            = var.rg_map[each.value.rg_name].location
  resource_group_name = var.rg_map[each.value.rg_name].name
}

# NSG ASSOCIATION
resource "azurerm_subnet_network_security_group_association" "assoc" {
  for_each = {
    for s in var.network_data :
    s.subnet_name => s
  }

  subnet_id = azurerm_subnet.subnet[each.key].id

  network_security_group_id = azurerm_network_security_group.nsg[
    each.value.nsg_name
  ].id
}

output "subnet_ids" {
  value = {
    for k, v in azurerm_subnet.subnet : k => v.id
  }
}