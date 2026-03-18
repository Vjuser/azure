# 🚀 Azure Linux VM with Terraform

This project automates the creation of a Linux Virtual Machine in the **vj-RG** resource group on Azure.

## 🛠 Features
* Automated VNET and Subnet creation.
* Static Public IP for easy access.
* Ubuntu 22.04 LTS OS.

## 📋 Prerequisites
* Azure CLI installed and logged in (`az login`).
* Terraform installed.

## 🚀 How to Run
1. Clone the repo.
2. Run `terraform init`.
3. Run `terraform apply -auto-approve`.