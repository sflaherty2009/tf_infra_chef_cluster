# dvo_infra_chef_cluster

This template is used to create the infrastucture necessary for Chef Automate

## Usage

`terraform plan`

`terraform apply`

If you need to add or remove a runner:

- update default value of runner_count in variables.tf & `terraform apply`

If you need to rebuild:

- all runners: `terraform destroy -target=azurerm_virtual_machine.runner && terraform apply`
- single runner: `terraform destroy -target=azurerm_virtual_machine.runner[#] && terraform apply`
  - azl-chef-runr-01 = 0
  - azl-chef-runr-01 = 1
  - azl-chef-runr-01 = 2
- automate server: `terraform destroy -target=azurerm_virtual_machine.automate && terraform apply`
  - this will also rebuild all runners as they depend on automate
- chef server: `terraform destroy && terraform apply`
  - above command is easiest as automate & runners will be rebuilt upon chef server rebuild

## Terraform variables (Options)

All variables and descriptions can be found in variables.tf

## Files in the configuration

automate.tf

- creates resource group, private ips, storage account and virtual machine necessary for chef automate server
- updates /etc/hosts on the runner vm as necessary
- completes preflight changes and runs a preflight check before installing chef automate
- installs azure cli, pulls down necessary files from azure file share and installs & configures chef automate

chef.tf

- creates resource group, private ips, storage account and virtual machine necessary for chef server
- updates /etc/hosts on the runner vm as necessary
- installs azure cli, installs & configures chef automate & uploads necessary files to an azure file share for use with chef automate

provider.tf

- sets location for terraform state file
- sets subscription id to production

runner.tf

- creates resource group, private ips, storage accounts and virtual machines necessary for automate runners
- updates /etc/hosts on the runner vm as necessary
- ssh into automate server and perform the install-runner command to setup server as a runner

variables.tf

- contains all variables necessary for all vms

### Secrets

- All located in the 'secrets' directory of the project.

| File                 | Purpose |
| ---------------------|--------------------------------------------------------------------------------------------|
| admin_credentials    | linux admin user credentials. User name on the first line, password on the second.         |
| azure_storage        | azchefsecrets service principal credentials. In LastPass                                   |
| data_collector_token | Data collector token for communication between Chef and Automate. Uses the default for now |
| automate.license     | Chef Automate license file                                                                 |

## Notes

- Users are created for Matthew Oleksowicz, Drew Easland, and Scott Flaherty with temporary passwords for both Chef and Automate. These should be changed by their respective users as soon as possible.
- SNMPD is installed and configured by the Terraform project. Within PRTG auto discovery can be run to establish most basic sensors. Additionally, the following sensors should be configured manually:
  - SSL Certificate Sensor (Port 443)
  - SSL Security Check Sensor (Port 443)
  - HTTP

## Maintainers

Drew Easland (drew_easland@trekbikes.com)

