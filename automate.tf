### AUTOMATE #####
# Create resource group that will be used with automate deploy
resource "azurerm_resource_group" "automate" {
  name       = "${var.auto_resource_group}"
  location   = "${var.location}"
  depends_on = ["azurerm_virtual_machine.chef"]
}

# Create virtual NIC that will be used with our automate instance.
resource "azurerm_network_interface" "automate" {
  name                = "${var.auto_computer_name}-nic"
  location            = "${azurerm_resource_group.automate.location}"
  resource_group_name = "${azurerm_resource_group.automate.name}"

  ip_configuration {
    name                          = "${var.auto_computer_name}-ipconf"
    subnet_id                     = "${var.subnet_id}"
    private_ip_address_allocation = "static"
    private_ip_address            = "10.16.192.7"
  }
}

# Storage Account & Container
resource "azurerm_storage_account" "automate" {
  name                     = "azlchefauto01s"
  resource_group_name      = "${azurerm_resource_group.automate.name}"
  location                 = "${azurerm_resource_group.automate.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "automate" {
  name                  = "vhds"
  resource_group_name   = "${azurerm_resource_group.automate.name}"
  storage_account_name  = "${azurerm_storage_account.automate.name}"
  container_access_type = "private"
}

# VIRTUAL MACHINE 
resource "azurerm_virtual_machine" "automate" {
  name                  = "${var.auto_computer_name}"
  location              = "${azurerm_resource_group.automate.location}"
  resource_group_name   = "${azurerm_resource_group.automate.name}"
  network_interface_ids = ["${azurerm_network_interface.automate.id}"]
  vm_size               = "${var.auto_vm_size}"

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
    vhd_uri       = "${azurerm_storage_account.automate.primary_blob_endpoint}${azurerm_storage_container.automate.name}/osdisk.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
    disk_size_gb  = "128"
  }

  os_profile {
    computer_name  = "${var.auto_computer_name}"
    admin_username = "${local.admin_user}"
    admin_password = "${local.admin_password}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

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
    source      = "secrets/delivery.license"
    destination = "/home/${local.admin_user}/delivery.license"
  }

  # PREFLIGHT UPDATES
  provisioner "remote-exec" {
    inline = [
      "sudo su -c 'echo 127.0.0.1 localhost > /etc/hosts'",
      "sudo su -c 'echo ${azurerm_network_interface.automate.private_ip_address} ${var.auto_computer_name} >> /etc/hosts'",
      "sudo su -c 'echo ${azurerm_network_interface.chef.private_ip_address} ${var.chef_computer_name} >> /etc/hosts'",
      "sudo sysctl -w vm.swappiness=1",
      "sudo sysctl -w vm.max_map_count=256000",
      "sudo sysctl -w vm.dirty_expire_centisecs=30000",
      "sudo sysctl -w net.ipv4.ip_local_port_range='35000 65000'",
      "echo 'never' | sudo tee /sys/kernel/mm/transparent_hugepage/enabled",
      "echo 'never' | sudo tee /sys/kernel/mm/transparent_hugepage/defrag",
      "sudo su -c 'echo /dev/sda1 / ext4 noatime 0 0 >> /etc/fstab' && sudo mount -o remount,noatime   /",
      "sudo blockdev --setra 4096 /dev/sda1",
    ]
  }

  # AUTOMATE INSTALLATION
  provisioner "remote-exec" {
    inline = [
      "echo 'deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ xenial main' | sudo tee /etc/apt/sources.list.d/azure-cli.list",
      "curl -L https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -",
      "sudo apt-get update",
      "sudo apt-get -y install wget apt-transport-https azure-cli",
      "sudo az login --service-principal -u ${local.azure_service_principal} -p ${local.azure_password} --tenant ${local.azure_tenant_id}",
      "sudo az storage file download --path delivery-user.pem --share-name automate --dest /home/${local.admin_user}/delivery-user.pem --account-name ${local.azure_account_name} --account-key ${local.azure_account_key}",
      "sudo wget -P /tmp --quiet ${var.automate_package_url}${var.automate_package_name}",
      "sudo dpkg -i /tmp/${var.automate_package_name}",
      "sudo automate-ctl preflight-check",
      "sudo automate-ctl setup --license /home/${local.admin_user}/delivery.license --key /home/${local.admin_user}/delivery-user.pem --server-url https://${var.chef_computer_name}/organizations/trek --fqdn ${var.auto_computer_name} --enterprise trek --configure --no-build-node",
      "sudo az storage file upload --share-name automate --source /etc/delivery/trek-admin-credentials --account-name ${local.azure_account_name} --account-key ${local.azure_account_key}",
    ]
  }

  # SNMPD INSTALLATION
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y install snmp snmp-mibs-downloader",
    ]
  }

  provisioner "file" {
    source      = "templates/snmpd.conf"
    destination = "/home/${local.admin_user}/snmpd.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /home/${local.admin_user}/snmpd.conf /etc/snmp/snmpd.conf",
      "sudo chown root:root /etc/snmp/snmpd.conf",
      "sudo chmod 0644 /etc/snmp/snmpd.conf",
      "sudo systemctl enable snmpd --now",
      "sudo systemctl restart snmpd",
    ]
  }
}

module "backup_vm_automate" {
  source                          = "git::https://bitbucket.org/trekbikes/dvo_module_backup_vm.git"

  recovery_vault_rg               = "az-rg-rv-prod"
  recovery_vault_name             = "AZ-RV-prod"
  virtual_machines_resource_group = "${azurerm_resource_group.automate.name}"
  virtual_machines_list           = "${azurerm_virtual_machine.automate.name}"
  backup_policy                   = "TrekDailyBackupPolicy"

  depends_on                      = [
    "${azurerm_virtual_machine.automate.id}"
  ]
}
