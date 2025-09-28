# Network Security Group para Zipkin VM
resource "azurerm_network_security_group" "zipkin" {
  name                = "zipkin-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "HTTP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9411"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "SSH"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = "production"
    Service     = "zipkin"
  }
}

# Public IP para Zipkin VM
resource "azurerm_public_ip" "zipkin" {
  name                = "zipkin-public-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = "production"
    Service     = "zipkin"
  }
}

# Network Interface para Zipkin VM
resource "azurerm_network_interface" "zipkin" {
  name                = "zipkin-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = module.network.cache_subnet_id # Usar subnet existente
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.zipkin.id
  }

  tags = {
    Environment = "production"
    Service     = "zipkin"
  }
}

# Asociar NSG con NIC
resource "azurerm_network_interface_security_group_association" "zipkin" {
  network_interface_id      = azurerm_network_interface.zipkin.id
  network_security_group_id = azurerm_network_security_group.zipkin.id
}

# Zipkin VM - ULTRA OPTIMIZADA
resource "azurerm_linux_virtual_machine" "zipkin" {
  name                = "zipkin-vm"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = "Standard_B1s" # MÁS ECONÓMICA: 1 vCPU, 1GB RAM, burstable
  admin_username      = "azureuser"

  # Deshabilitar autenticación por contraseña
  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.zipkin.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.zipkin.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS" # ECONÓMICO: HDD estándar (suficiente para Zipkin)
    disk_size_gb         = 30             # Mínimo necesario
  }

  # Ubuntu 22.04 LTS - imagen estándar y verificada
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  # Script de inicialización ULTRA OPTIMIZADO
  custom_data = base64encode(file("${path.module}/zipkin-startup.sh"))

  tags = {
    Environment = "production"
    Service     = "zipkin"
    Performance = "optimized"
  }

  depends_on = [
    azurerm_resource_group.main,
    azurerm_network_interface_security_group_association.zipkin
  ]
}

# Generar SSH key para la VM
resource "tls_private_key" "zipkin" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Output de la clave privada (para acceso SSH)
resource "local_file" "zipkin_private_key" {
  content         = tls_private_key.zipkin.private_key_pem
  filename        = "${path.module}/zipkin-vm-key.pem"
  file_permission = "0600"
}