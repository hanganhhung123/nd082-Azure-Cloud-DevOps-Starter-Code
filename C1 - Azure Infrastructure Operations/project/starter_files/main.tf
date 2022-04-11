provider "azurerm" {
    version         = "=3.1.0"
    subscription_id = "9d61b3b3-598e-4f7b-8f9a-1a62ddbdd2e0"
    tenant_id       = "40127cd4-45f3-49a3-b05d-315a43a9f033"
    features{
        key_vault {
            recover_soft_deleted_key_vaults = false
            purge_soft_delete_on_destroy    = false
        }
    }
}

locals {
    location    = var.location
    vm_count    = var.vm_count
}
resource "azurerm_resource_group" "linux-rg" {
    name     = "linux"
    location = var.location
}

resource "azurerm_virtual_network" "linux-vnet" {
    name    = "linux-vnet"
    address_space       = ["10.0.0.0/16"]
    location            = azurerm_resource_group.linux-rg.location
    resource_group_name = azurerm_resource_group.linux-rg.name
    
    tags = {
        hanganhhung = var.hanganhhung
    }
}

resource "azurerm_subnet" "linux-subnet" {
    name    = "linux-subnet"
    resource_group_name = azurerm_resource_group.linux-rg.name
    virtual_network_name = azurerm_virtual_network.linux-vnet.name
    address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "linux-nsg" {
    name                = "linux-nsg"
    location            = azurerm_resource_group.linux-rg.location
    resource_group_name = azurerm_resource_group.linux-rg.name

    security_rule {
        name                       = "AllowSSHInbound"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "DenyInternetInbound"
        priority                   = 200
        direction                  = "Inbound"
        access                     = "Deny"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "Internet"
        destination_address_prefix = "*"
    }
    
    tags = {
        hanganhhung = var.hanganhhung
    }
}

resource "azurerm_network_interface" "linux-ni" {
    name                = "linux-ni"
    location            = azurerm_resource_group.linux-rg.location
    resource_group_name = azurerm_resource_group.linux-rg.name

    ip_configuration {
        name                          = "internal"
        subnet_id                     = azurerm_subnet.linux-subnet.id
        private_ip_address_allocation = "Dynamic"
    }
    
    tags = {
        hanganhhung = var.hanganhhung
    }
}

resource "azurerm_network_interface_security_group_association" "linux-ni-assoc-sc" {
    network_interface_id      = azurerm_network_interface.linux-ni.id
    network_security_group_id = azurerm_network_security_group.linux-nsg.id
}

resource "azurerm_public_ip" "linux-public-ip" {
    name                = "linux-public-ip"
    resource_group_name = azurerm_resource_group.linux-rg.name
    location            = azurerm_resource_group.linux-rg.location
    allocation_method   = "Static"
    
    tags = {
        hanganhhung = var.hanganhhung
    }
}

resource "azurerm_lb" "linux-lb" {
    name                = "linux-lb"
    location            = azurerm_resource_group.linux-rg.location
    resource_group_name = azurerm_resource_group.linux-rg.name

    frontend_ip_configuration {
        name                 = "PublicIPAddress"
        public_ip_address_id = azurerm_public_ip.linux-public-ip.id
    }
    
    tags = {
        hanganhhung = var.hanganhhung
    }

    depends_on = [
      azurerm_public_ip.linux-public-ip
    ]
}

resource "azurerm_lb_backend_address_pool" "linux-lbbap" {
    name            = "Linux-lbbap"
    loadbalancer_id = azurerm_lb.linux-lb.id
    
    depends_on = [
      azurerm_lb.linux-lb
    ]
}

resource "azurerm_network_interface_backend_address_pool_association" "linux-nic-assoc-lb" {
    ip_configuration_name   = "internal"
    network_interface_id    = azurerm_network_interface.linux-ni.id
    backend_address_pool_id = azurerm_lb_backend_address_pool.linux-lbbap.id
    
    depends_on = [
      azurerm_network_interface.linux-ni,
      azurerm_lb.linux-lb
    ]
}

resource "azurerm_availability_set" "linux-as" {
    name                            = "linux-as"
    location                        = azurerm_resource_group.linux-rg.location
    resource_group_name             = azurerm_resource_group.linux-rg.name
    platform_update_domain_count    = 1
    platform_fault_domain_count     = 1
    tags = {
        hanganhhung = var.hanganhhung
    }
}

data "azurerm_image" "linux-image-search" {
    name                = "LinuxImage"
    resource_group_name = "image-rg"
}

resource "azurerm_virtual_machine" "linutil" {
    count                            = local.vm_count
    name                             = format("linutil-%d", count.index + 1)
    location                         = azurerm_resource_group.linux-rg.location
    resource_group_name              = azurerm_resource_group.linux-rg.name
    network_interface_ids            = [azurerm_network_interface.linux-ni.id]
    vm_size                          = "Standard_B2ms"
    delete_os_disk_on_termination    = true
    delete_data_disks_on_termination = true

    storage_image_reference {
        id = "${data.azurerm_image.linux-image-search.id}"
    }

    storage_os_disk {
        name              = format("linutil-os-disk-%d", count.index + 1)
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    os_profile {
        computer_name  = format("linutil-%d", count.index + 1)
        admin_username = "anhhung"
        admin_password = "Anhhung123@"
    }

    os_profile_linux_config {
        disable_password_authentication = false
    }

    tags = {
        hanganhhung = var.hanganhhung
    }
}

resource "azurerm_managed_disk" "linux-managed-disk" {
    count                = var.vm_count
    name                 = format("linutil-manage-disk-%d", count.index + 1)
    location             = azurerm_resource_group.linux-rg.location
    resource_group_name  = azurerm_resource_group.linux-rg.name
    storage_account_type = "Standard_LRS"
    create_option        = "Empty"
    disk_size_gb         = "1"

    tags = {
        hanganhhung = var.hanganhhung
    }
}

resource "azurerm_virtual_machine_data_disk_attachment" "managed_disk_attach" {
    count              = var.vm_count
    managed_disk_id    = azurerm_managed_disk.linux-managed-disk.*.id[count.index]
    virtual_machine_id = azurerm_virtual_machine.linutil.*.id[count.index]
    lun                = count.index + 10
    caching            = "ReadWrite"
}