variable "location" {
  type    = string
  default = "westeurope"
}
variable "resource_prefix" {
  type    = string
  default = "k8sVM"
}

#variable for environment
variable "environment" {
  type    = string
  default = "kb8s"
}
variable "node_count_worker" {
  type    = number
  default = 2
}

variable "node_count_master" {
  type    = number
  default = 1
}

variable "vm_image" {
  type        = map(string)
  description = "Virtual machine source image information"
  default     = {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS" 
    version   = "latest"
  }
}

variable "size-vm-worker"{
  default = "Standard_B1ms"
}

variable "size-vm-master"{
  default = "Standard_B2S"
}