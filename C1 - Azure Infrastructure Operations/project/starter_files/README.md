# Azure Infrastructure Operations Project: Deploying a scalable IaaS web server in Azure

### Introduction
For this project, you will write a Packer template and a Terraform template to deploy a customizable, scalable web server in Azure.

### Getting Started
1. Clone this repository

2. Create your infrastructure as code

3. Update this README to reflect how someone would use your code.

### Dependencies
1. Create an [Azure Account](https://portal.azure.com) 
2. Install the [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. Install [Packer](https://www.packer.io/downloads)
4. Install [Terraform](https://www.terraform.io/downloads.html)

### Instructions
**1. Login to Azure by AzureCLI.**\
**2. Deploy Azure policy.**
- Change **subscription_id** to your Azure subscription id.
- Create policy definition.
```
az policy definition create --name tagging-policy --rules azurepolicy.rules.json --params azurepolicy.parameters.json
```
- Create policy assessment.
```
az policy assignment create --policy tagging-policy -p '{ "author": { "value": "hanganhhung" }}' --name tagging-policy --display-name tagging-policy -e Default
```
**3. Deploy Linux Image by Packer.**
- Create new resource group to store new image.
```
az group create -l australiaeast -n image-rg
```
- Deploy new image.
```
packer build server.json
```
**4. Deploy Azure resources by terraform.**
- Deploy main.tf
```
terraform plan -out solution.plan
terraform apply
```
- For customize use (Ex: Difference location & number of Linux Vms)
    - Change default value in variable.tf to customize needs.
    - Or:
```
terraform plan terraform plan -out solution.plan -var="location=<location>" -var="vm_count=<vm_count>"
```
### Output
**1. Deploy Azure policy successfully .**
- Check result.
```
az policy assignment list
```
- Result.

**3. Deploy Linux Image successfully.**
- Check result.
```
az image list
```
- Result.

**4. Deploy Azure resources successfully.**
