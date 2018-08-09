#### CHEF ####
# Create resource group that will be used with chef deploy
resource "azurerm_resource_group" "chef" {
  name     = "${var.chef_resource_group}"
  location = "${var.location}"
}

# Create public IPs
resource "azurerm_public_ip" "chef" {
  name                         = "${var.chef_computer_name}-pubip"
  location                     = "${azurerm_resource_group.chef.location}"
  resource_group_name          = "${azurerm_resource_group.chef.name}"
  public_ip_address_allocation = "static"
  domain_name_label            = "${var.chef_computer_name}"
}

# Create virtual NIC that will be used with our chef instance.
resource "azurerm_network_interface" "chef" {
  name                = "${var.chef_computer_name}-nic"
  location            = "${azurerm_resource_group.chef.location}"
  resource_group_name = "${azurerm_resource_group.chef.name}"

  ip_configuration {
    name                          = "${var.chef_computer_name}-ipconf"
    subnet_id                     = "${var.subnet_id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${element(azurerm_public_ip.chef.*.id, count.index)}"
  }
}

# Storage Account & Container
resource "azurerm_storage_account" "chef" {
  name                     = "azlchefsrvr01s"
  resource_group_name      = "${azurerm_resource_group.chef.name}"
  location                 = "${azurerm_resource_group.chef.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "chef" {
  name                  = "vhds"
  resource_group_name   = "${azurerm_resource_group.chef.name}"
  storage_account_name  = "${azurerm_storage_account.chef.name}"
  container_access_type = "private"
}

# VIRTUAL MACHINE 
resource "azurerm_virtual_machine" "chef" {
  name                  = "${var.chef_computer_name}"
  location              = "${azurerm_resource_group.chef.location}"
  resource_group_name   = "${azurerm_resource_group.chef.name}"
  network_interface_ids = ["${azurerm_network_interface.chef.id}"]
  vm_size               = "${var.chef_vm_size}"

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "${var.publisher}"
    offer     = "${var.offer}"
    sku       = "${var.sku}"
    version   = "${var.version}"
  }

  storage_os_disk {
    name          = "osdisk"
    vhd_uri       = "${azurerm_storage_account.chef.primary_blob_endpoint}${azurerm_storage_container.chef.name}/osdisk.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
    disk_size_gb  = "128"
  }

  os_profile {
    computer_name  = "${var.chef_computer_name}"
    admin_username = "${local.admin_user}"
    admin_password = "${local.admin_password}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  provisioner "remote-exec" {
    inline = [
      "sudo su -c 'echo 127.0.0.1 ${var.chef_computer_name} localhost > /etc/hosts'",
      "sudo su -c 'echo ${azurerm_network_interface.chef.private_ip_address} ${var.chef_computer_name} >> /etc/hosts'",
      "echo 'deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ xenial main' | sudo tee /etc/apt/sources.list.d/azure-cli.list",
      "curl -L https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -",
      "sudo apt-get update",
      "sudo apt-get -y install wget apt-transport-https azure-cli",
      "sudo wget -P /tmp --quiet ${var.chef_server_package_url}${var.chef_server_package_name}",
      "sudo dpkg -i /tmp/${var.chef_server_package_name}",
      "sudo chef-server-ctl reconfigure",
      "sudo chef-server-ctl user-create delivery Delivery User delivery-user@chef.io ChefDelivery2017 --filename /home/${local.admin_user}/delivery-user.pem",
      "sudo chef-server-ctl org-create trek 'Trek Bikes' --filename /home/${local.admin_user}/trek-validator.pem -a delivery",
      "sudo az login --service-principal -u ${local.azure_service_principal} -p ${local.azure_password} --tenant ${local.azure_tenant_id}",
      "sudo az storage file upload --share-name automate --source /home/${local.admin_user}/delivery-user.pem --account-name ${local.azure_account_name} --account-key ${local.azure_account_key}",
      "sudo az storage file upload --share-name automate --source /home/${local.admin_user}/trek-validator.pem --account-name ${local.azure_account_name} --account-key ${local.azure_account_key}",
    ]

    connection {
      type             = "ssh"
      host             = "${element(azurerm_network_interface.chef.*.private_ip_address, count.index)}"
      user             = "${local.admin_user}"
      password         = "${local.admin_password}"
      agent            = false
      bastion_host     = "azl-prd-jmp-01-az-rg-jump-lin.eastus2.cloudapp.azure.com"
      bastion_port     = "4222"
      bastion_user     = "${local.admin_user}"
      bastion_password = "${local.admin_password}"
    }
  }
}