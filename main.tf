# Create Linux Public IP
resource "azurerm_public_ip" "example_public_ip" {
  count = sum([var.node_count_master,var.node_count_worker])
  name  = "${var.resource_prefix}-${format("%02d", count.index)}-PublicIP"
  #name = "${var.resource_prefix}-PublicIP"
  location            = azurerm_resource_group.vnet.location
  resource_group_name = azurerm_resource_group.vnet.name
  allocation_method   = var.environment == "Test" ? "Static" : "Dynamic"
  tags = {
    environment = "Test"
  }
}
# Create Network Interface
resource "azurerm_network_interface" "example_nic" {
  count = var.node_count_master+var.node_count_worker
  #name = "${var.resource_prefix}-NIC"
  name                = "${var.resource_prefix}-${format("%02d", count.index)}-NIC"
  location            = azurerm_resource_group.vnet.location
  resource_group_name = azurerm_resource_group.vnet.name
  #
  ip_configuration {
    name                          = "internal"
    subnet_id                     = module.vnet.vnet_subnets[0]
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = element(azurerm_public_ip.example_public_ip.*.id, count.index)
    #public_ip_address_id = azurerm_public_ip.example_public_ip.id
    #public_ip_address_id = azurerm_public_ip.example_public_ip.id
  }
}
# Creating resource NSG
resource "azurerm_network_security_group" "example_nsg" {
  name                = "${var.resource_prefix}-NSG"
  location            = azurerm_resource_group.vnet.location
  resource_group_name = azurerm_resource_group.vnet.name
  # Security rule can also be defined with resource azurerm_network_security_rule, here just defining it inline.
  security_rule {
    name                       = "Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags = {
    environment = "Test"
  }
}
# Subnet and NSG association
resource "azurerm_subnet_network_security_group_association" "example_subnet_nsg_association" {
  subnet_id                 = module.vnet.vnet_subnets[0]
  network_security_group_id = azurerm_network_security_group.example_nsg.id
}

data "template_file" "linux-vm-cloud-init" {
  template = file("user-data-docker.sh")
}
# Virtual Machine Creation — Linux
resource "azurerm_linux_virtual_machine" "master_linux_vm" {
  count                         = var.node_count_master
  name                          = "${var.resource_prefix}-${format("%02d", count.index)}"
  location                      = azurerm_resource_group.vnet.location
  resource_group_name           = azurerm_resource_group.vnet.name
  network_interface_ids         = [element(azurerm_network_interface.example_nic.*.id, count.index)]
  size                          = var.size-vm-master
  admin_username = "kubeMaster"
  source_image_reference {
    offer     = lookup(var.vm_image, "offer", null)
    publisher = lookup(var.vm_image, "publisher", null)
    sku       = lookup(var.vm_image, "sku", null)
    version   = lookup(var.vm_image, "version", null)
  }
  os_disk {
    name                 = "myosdisk-${count.index}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  computer_name  = "${var.resource_prefix}-0"

  admin_ssh_key{
    public_key = data.azurerm_key_vault_secret.vm_client_sshpubkey.value
    username = "kubeMaster"
  }

  custom_data = base64encode(data.template_file.linux-vm-cloud-init.rendered)
  disable_password_authentication = true
  tags = {
    environment = var.environment
  }
}

# Virtual Machine Creation — Linux
resource "azurerm_linux_virtual_machine" "worker_linux_vm" {
  count                         = var.node_count_worker
  name                          = "${var.resource_prefix}-${format("%02d", count.index+1)}"
  location                      = azurerm_resource_group.vnet.location
  resource_group_name           = azurerm_resource_group.vnet.name
  network_interface_ids         = [element(azurerm_network_interface.example_nic.*.id, sum([count.index,1]))]
  size                          = var.size-vm-worker
  admin_username = "kubeWorker"
  source_image_reference {
    offer     = lookup(var.vm_image, "offer", null)
    publisher = lookup(var.vm_image, "publisher", null)
    sku       = lookup(var.vm_image, "sku", null)
    version   = lookup(var.vm_image, "version", null)
  }
  os_disk {
    name                 = "myosdisk-${count.index+1}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  computer_name  = "${var.resource_prefix}-${format("%02d", count.index+1)}"

  admin_ssh_key{
    public_key = data.azurerm_key_vault_secret.vm_client_sshpubkey.value
    username = "kubeWorker"
  }

  custom_data = base64encode(data.template_file.linux-vm-cloud-init.rendered)
  disable_password_authentication = true
  tags = {
    environment = var.environment
  }
}

