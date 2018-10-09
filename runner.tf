#### RUNNER(S) ####
# Create resource group that will be used with runner deploy(s)
resource "azurerm_resource_group" "runner" {
  name       = "${var.runner_resource_group}"
  location   = "${var.location}"
  depends_on = ["azurerm_virtual_machine.automate"]
}

# Create virtual NIC that will be used with our runner instance(s).
resource "azurerm_network_interface" "runner" {
  name                = "${var.runner_computer_name}-${format("%02d", count.index+1)}-nic"
  location            = "${azurerm_resource_group.runner.location}"
  resource_group_name = "${azurerm_resource_group.runner.name}"
  count               = "${var.runner_count}"

  ip_configuration {
    name                          = "${var.runner_computer_name}-${format("%02d", count.index+1)}-ipconf"
    subnet_id                     = "${var.subnet_id}"
    private_ip_address_allocation = "dynamic"
  }
}

# Storage Account & Container
resource "azurerm_storage_account" "runner" {
  name                     = "azlchefrunr${format("%02d", count.index+1)}s"
  resource_group_name      = "${azurerm_resource_group.runner.name}"
  location                 = "${azurerm_resource_group.runner.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  count                    = "${var.runner_count}"
}

resource "azurerm_storage_container" "runner" {
  name                  = "vhds"
  resource_group_name   = "${azurerm_resource_group.runner.name}"
  storage_account_name  = "${element(azurerm_storage_account.runner.*.name, count.index)}"
  container_access_type = "private"
  count                 = "${var.runner_count}"
}

# VIRTUAL MACHINE 
resource "azurerm_virtual_machine" "runner" {
  name                  = "${var.runner_computer_name}-${format("%02d", count.index+1)}"
  location              = "${azurerm_resource_group.runner.location}"
  resource_group_name   = "${azurerm_resource_group.runner.name}"
  network_interface_ids = ["${element(azurerm_network_interface.runner.*.id, count.index)}"]
  vm_size               = "${var.runner_vm_size}"
  count                 = "${var.runner_count}"

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
    vhd_uri       = "${element(azurerm_storage_account.runner.*.primary_blob_endpoint, count.index)}${element(azurerm_storage_container.runner.*.name, count.index)}/osdisk.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
    disk_size_gb  = "128"
  }

  os_profile {
    computer_name  = "${var.runner_computer_name}-${format("%02d", count.index+1)}"
    admin_username = "${local.admin_user}"
    admin_password = "${local.admin_password}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  provisioner "remote-exec" {
    inline = [
      "sudo su -c 'echo 127.0.0.1 localhost > /etc/hosts'",
      "sudo su -c 'echo ${element(azurerm_network_interface.runner.*.private_ip_address, count.index)} ${var.runner_computer_name}-${format("%02d", count.index+1)} >> /etc/hosts'",
      "sudo su -c 'echo ${element(azurerm_network_interface.chef.*.private_ip_address, count.index)} ${var.chef_computer_name} >> /etc/hosts'",
      "sudo su -c 'echo ${element(azurerm_network_interface.automate.*.private_ip_address, count.index)} ${var.auto_computer_name} >> /etc/hosts'",
    ]

    connection {
      type             = "ssh"
      host             = "${element(azurerm_network_interface.runner.*.private_ip_address, count.index)}"
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

resource "null_resource" "runners" {
  connection {
    type             = "ssh"
    host             = "${element(azurerm_network_interface.automate.*.private_ip_address, count.index)}"
    user             = "${local.admin_user}"
    password         = "${local.admin_password}"
    agent            = false
    bastion_host     = "azl-prd-jmp-01-az-rg-jump-lin.eastus2.cloudapp.azure.com"
    bastion_port     = "4222"
    bastion_user     = "${local.admin_user}"
    bastion_password = "${local.admin_password}"
  }

  provisioner "file" {
    source      = "templates/install-runners.sh"
    destination = "/tmp/install-runners.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod 744 /tmp/install-runners.sh"
      "sudo /tmp/install-runners.sh '${var.runner_computer_name}' '${var.runner_count}' '${local.admin_user}' '${local.admin_password}' '${var.runner_chefdk_version}' '${join("' ", azurerm_network_interface.runner.*.private_ip_address)}"'
    ]
  }
}
