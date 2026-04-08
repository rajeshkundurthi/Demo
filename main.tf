############################################
# 🔹 LOCALS - READ INPUT FILES
############################################

locals {
  # RGs from CSV
  resource_groups = csvdecode(file("${path.module}/resource_groups.txt"))

  # VNets from TXT
  vnets = [
    for line in split("\n", file("${path.module}/vnets.txt")) :
    {
      name          = trimspace(split(",", line)[0])
      address_space = trimspace(split(",", line)[1])
      location      = trimspace(split(",", line)[2])
      rg_name       = trimspace(split(",", line)[3])

      subnets = [
        for sn in split("|", split(",", line)[4]) :
        {
          name = trimspace(split(":", sn)[0])
          cidr = trimspace(split(":", sn)[1])
        }
      ]
    }
    if length(trimspace(line)) > 0
  ]
}

############################################
# 🔹 CREATE RESOURCE GROUPS
############################################

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

############################################
# 🔹 CREATE VNets
############################################

resource "azurerm_virtual_network" "vnet" {
  for_each = {
    for vnet in local.vnets : vnet.name => vnet
  }

  name          = each.value.name
  location      = each.value.location
  address_space = [each.value.address_space]

  resource_group_name = azurerm_resource_group.rg[each.value.rg_name].name

  tags = {
    CreatedBy = "Terraform"
  }
}

############################################
# 🔹 FLATTEN SUBNETS
############################################

locals {
  subnets = flatten([
    for vnet in local.vnets : [
      for subnet in vnet.subnets : {
        vnet_name = vnet.name
        rg_name   = vnet.rg_name
        name      = subnet.name
        cidr      = subnet.cidr
      }
    ]
  ])
}

############################################
# 🔹 CREATE SUBNETS
############################################

resource "azurerm_subnet" "subnet" {
  for_each = {
    for sn in local.subnets :
    "${sn.vnet_name}-${sn.name}" => sn
  }

  name                 = each.value.name
  resource_group_name  = azurerm_resource_group.rg[each.value.rg_name].name
  virtual_network_name = azurerm_virtual_network.vnet[each.value.vnet_name].name
  address_prefixes     = [each.value.cidr]
}