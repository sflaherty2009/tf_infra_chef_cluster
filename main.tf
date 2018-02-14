#### CHEF ####
# Create resource group that will be used with chef deploy
resource "azurerm_resource_group" "chef" {
  name     = "${var.chef_resource_group_name}"
  location = "${var.location}"
}

# Create public IPs
resource "azurerm_public_ip" "chef" {
    name                         = "${var.chef_computer_name}-pubip"
    location                     = "${azurerm_resource_group.chef.location}"
    resource_group_name          = "${azurerm_resource_group.chef.name}"
    public_ip_address_allocation = "static"
}

# Create virtual NIC that will be used with our chef instance.
resource "azurerm_network_interface" "chef" {
  name                = "${azurerm_resource_group.chef.name}-nic"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.chef.name}"

  ip_configuration {
    name                          = "${var.chef_computer_name}-ipconf"
    subnet_id                     = "${var.subnet_id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${element(azurerm_public_ip.chef.*.id, count.index)}"
  }
}

# VIRTUAL MACHINE 
resource "azurerm_virtual_machine" "chef" {
  name                  = "${var.chef_computer_name}"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.chef.name}"
  network_interface_ids = ["${azurerm_network_interface.chef.id}"]
  vm_size               = "${var.vm_size}"

  storage_image_reference {
    publisher = "${var.publisher}"
    offer     = "${var.offer}"
    sku       = "${var.sku}"
    version   = "${var.version}"
  }

  storage_os_disk {
    name          = "${var.chef_computer_name}-osdisk"
    caching       = "ReadWrite"
    create_option = "FromImage"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = "100"
    os_type           = "linux"
  }

  os_profile {
    computer_name  = "${var.chef_computer_name}"
    admin_username = "${var.chef_admin_user}"
    admin_password = "${var.chef_admin_password}"
  }
  
  os_profile_linux_config {
    disable_password_authentication = false
      ssh_keys {
        path = "/home/${var.chef_admin_user}/.ssh/authorized_keys"
        key_data = "${file("~/.ssh/id_rsa.pub")}"
    }
  }
  connection {
      type = "ssh"
      host = "${element(azurerm_public_ip.chef.*.ip_address, count.index)}"
      user = "${var.chef_admin_user}"
      # password = "${var.admin_password}"
      private_key = "${file("~/.ssh/id_rsa")}"
      agent = false
  }
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get -y install wget",
      "sudo wget -P /tmp --quiet ${var.chef_server_package_url}",
      "sudo dpkg -i /tmp/${var.chef_server_package_name}",
      "sudo su -c 'echo 127.0.0.1 ${var.chef_computer_name} localhost > /etc/hosts'",
      "sudo chef-server-ctl reconfigure",
      "sudo chef-server-ctl user-create delivery Delivery User delivery-user@chef.io ChefDelivery2017 --filename /home/devops/delivery-user.pem",
      "sudo chef-server-ctl org-create delivery 'Chef Delivery'  --filename /home/devops/delivery-validator.pem -a delivery"
    ]
  }
  provisioner "local-exec" {
    # command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${file("~/.ssh/id_rsa")} devops@${element(azurerm_public_ip.chef.*.ip_address, count.index)}:/home/devops/delivery-user.pem /Users/sflaherty/workarea/trek/Terraform/dvo_infra_chef_cluster/"
    command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null devops@${element(azurerm_public_ip.chef.*.ip_address, count.index)}:/home/devops/delivery-user.pem /Users/sflaherty/workarea/trek/Terraform/dvo_infra_chef_cluster/"
  }

  provisioner "local-exec" {
    # command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${file("~/.ssh/id_rsa")} devops@${element(azurerm_public_ip.chef.*.ip_address, count.index)}:/home/devops/delivery-validator.pem /Users/sflaherty/workarea/trek/Terraform/dvo_infra_chef_cluster/"
    command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null devops@${element(azurerm_public_ip.chef.*.ip_address, count.index)}:/home/devops/delivery-validator.pem /Users/sflaherty/workarea/trek/Terraform/dvo_infra_chef_cluster/"

  }
}

### AUTOMATE #####
# Create resource group that will be used with automate deploy
resource "azurerm_resource_group" "automate" {
  name     = "${var.auto_resource_group_name}"
  location = "${var.location}"
}

# Create public IPs
resource "azurerm_public_ip" "automate" {
    name                         = "${var.auto_computer_name}-pubip"
    location                     = "${azurerm_resource_group.automate.location}"
    resource_group_name          = "${azurerm_resource_group.automate.name}"
    public_ip_address_allocation = "static"
}

# Create virtual NIC that will be used with our automate instance.
resource "azurerm_network_interface" "automate" {
  name                = "${azurerm_resource_group.automate.name}-nic"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.automate.name}"

  ip_configuration {
    name                          = "${var.auto_computer_name}-ipconf"
    subnet_id                     = "${var.subnet_id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${element(azurerm_public_ip.automate.*.id, count.index)}"
  }
}

# VIRTUAL MACHINE 
resource "azurerm_virtual_machine" "automate" {
  name                  = "${var.auto_computer_name}"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.automate.name}"
  network_interface_ids = ["${azurerm_network_interface.automate.id}"]
  vm_size               = "${var.vm_size}"

  storage_image_reference {
    publisher = "${var.publisher}"
    offer     = "${var.offer}"
    sku       = "${var.sku}"
    version   = "${var.version}"
  }

  storage_os_disk {
    name          = "${var.auto_computer_name}-osdisk"
    caching       = "ReadWrite"
    create_option = "FromImage"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = "100"
    os_type           = "linux"
  }

  os_profile {
    computer_name  = "${var.auto_computer_name}"
    admin_username = "${var.auto_admin_user}"
    admin_password = "${var.auto_admin_password}"
  }
  
  os_profile_linux_config {
    disable_password_authentication = false
      ssh_keys {
        path = "/home/${var.auto_admin_user}/.ssh/authorized_keys"
        key_data = "${file("~/.ssh/id_rsa.pub")}"
    }
  }

  connection {
      type = "ssh"
      host = "${element(azurerm_public_ip.automate.*.ip_address, count.index)}"
      user = "${var.auto_admin_user}"
      # password = "${var.admin_password}"
      private_key = "${file("~/.ssh/id_rsa")}"
      agent = false
  }
  provisioner "file" {
        source = "delivery-user.pem"
        destination = "/home/devops/delivery-user.pem"
  }

  provisioner "file" {
        source = "${var.license_file}"
        destination = "/home/devops/delivery.license"
  }

  provisioner "remote-exec" {
    inline = [
            "sudo apt-get update",
            "sudo apt-get -y install wget",
            "sudo wget -P /tmp --quiet ${var.automate_package_url}",
            "sudo wget -P /home/devops --quiet ${var.chefdk_package_url}",
            "sudo dpkg -i /tmp/${var.automate_package_name}",
            "sudo su -c 'echo 127.0.0.1 ${var.chef_computer_name} localhost > /etc/hosts'",
            "sudo automate-ctl setup --license /home/devops/delivery.license --key /home/devops/delivery-user.pem --server-url https://${element(azurerm_public_ip.automate.*.ip_address, count.index)}/organizations/delivery --fqdn ${element(azurerm_public_ip.automate.*.ip_address, count.index)} --enterprise delivery --configure --no-build-node"
        ]
  }

  provisioner "local-exec" {
        command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null devops@${element(azurerm_public_ip.automate.*.ip_address, count.index)}:/etc/delivery/delivery-admin-credentials /Users/sflaherty/workarea/trek/Terraform/dvo_infra_chef_cluster/"
  }
}