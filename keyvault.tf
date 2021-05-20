data "azurerm_key_vault" "keyvault" {
  name                = "mitsu"
  resource_group_name = "azurerm_key"
}

data "azurerm_key_vault_secret" "vm_client_sshpubkey" {
  name         = "ClientSSHpubkey"
  key_vault_id = data.azurerm_key_vault.keyvault.id
}
