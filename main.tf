provider "azurerm" {  
  features {}  
}  
  
resource "azurerm_resource_group" "example" {  
  name     = "example-resources"  
  location = "East US"  
}  
  
resource "azurerm_virtual_network" "example" {  
  name                = "example-network"  
  resource_group_name = azurerm_resource_group.example.name  
  location            = azurerm_resource_group.example.location  
  address_space       = ["10.0.0.0/16"]  
}  
  
resource "azurerm_subnet" "example" {  
  name                 = "internal"  
  resource_group_name  = azurerm_resource_group.example.name  
  virtual_network_name = azurerm_virtual_network.example.name  
  address_prefixes     = ["10.0.2.0/24"]  
}  
  
resource "azurerm_network_interface" "example" {  
  name                = "example-nic"  
  location            = azurerm_resource_group.example.location  
  resource_group_name = azurerm_resource_group.example.name  
  
  ip_configuration {  
    name                          = "internal"  
    subnet_id                     = azurerm_subnet.example.id  
    private_ip_address_allocation = "Dynamic"  
  }  
}  
  
resource "azurerm_windows_virtual_machine" "example" {  
  name                = "example-machine"  
  resource_group_name = azurerm_resource_group.example.name  
  location            = azurerm_resource_group.example.location  
  size                = "Standard_DS1_v2"  
  network_interface_ids = [azurerm_network_interface.example.id ]
  admin_username = "adminuser"  
  admin_password = "P@ssw0rd123!"  
  enable_automatic_updates = true  
  
  os_disk {  
    caching              = "ReadWrite"  
    storage_account_type = "Standard_LRS" 
    
  }  
  
  source_image_reference {  
    publisher = "MicrosoftWindowsDesktop"  
    offer     = "Windows-11"  
    sku       = "win11-22h2-ent"  
    version   = "latest"  
  }  

  secure_boot_enabled = true  
  vtpm_enabled = true
  

  depends_on = [ azurerm_network_interface.example ]
}  


resource "azurerm_virtual_machine_extension" "example" {  
  name                 = "GuestAttestation"  
  virtual_machine_id   = azurerm_windows_virtual_machine.example.id  
  publisher            = "Microsoft.Azure.Security.WindowsAttestation"  
  type                 = "GuestAttestation"  
  type_handler_version = "1.0"  
  auto_upgrade_minor_version = true  
  
  settings = <<SETTINGS
 { 
      
        "Authentication": "MSI",  
        "AttestationType": "GuestAttestation"  
    }  
SETTINGS  
}  

resource "null_resource" "azcli1" {
   
   provisioner "local-exec" {
    
    interpreter = ["/bin/bash", "-c"]
    command = "az vm run-command invoke --command-id RunPowerShellScript --name ${format("%s",azurerm_windows_virtual_machine.example.name)} --resource-group ${azurerm_resource_group.example.name} --scripts @getprocess.ps1"
  
  }
}

variable "sub" {
  type        = string
  default     = "8e09ea39-a872-4c44-91e8-b80ddcafcd7c"
}

resource "null_resource" "azrest" {
   
   provisioner "local-exec" {
    
    interpreter = ["/bin/bash", "-c"]
    command = "az rest --method post --uri https://management.azure.com/subscriptions/${var.sub}/resourcegroups/${azurerm_resource_group.example.name}/providers/Microsoft.Compute/virtualMachines/${azurerm_windows_virtual_machine.example.name}/powerOff?api-version=2021-04-01"
  
  }
}