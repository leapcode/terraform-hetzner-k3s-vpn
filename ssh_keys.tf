resource "hcloud_ssh_key" "admins" {
  for_each   = { for admin in var.admins : admin.name => admin if !contains([for k in data.hcloud_ssh_keys.all.ssh_keys : k.name], admin.name) }
  name       = each.value.name
  public_key = each.value.public_key
}
