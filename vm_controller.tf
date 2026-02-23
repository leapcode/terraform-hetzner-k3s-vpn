resource "hcloud_server" "k3s_controller" {
  count       = var.k3s_leader_count
  name        = "${var.k3s_cluster_name}-controller-${count.index}"
  server_type = var.k3s_controller_server_type
  image       = var.k3s_base_os
  ssh_keys    = local.admin_ssh_key_ids
  datacenter  = var.datacenter

  user_data = templatefile("${path.module}/templates/cloud-init.sh", {
    k3s_token            = random_password.k3s_token.result,
    k3s_url              = "",
    total_leaders        = var.k3s_leader_count
    leader_count         = "${count.index}"
    private_ip           = cidrhost(hcloud_network_subnet.controllers.ip_range, 2 + count.index)
    floating_ip          = var.gateway_mode_enabled ? hcloud_floating_ip.k3s_controller[count.index].ip_address : ""
    cluster_cidr         = var.k3s_cluster_cidr
    service_cidr         = var.k3s_service_cidr
    cluster_dns          = var.k3s_cluster_dns
    gateway_mode_enabled = var.gateway_mode_enabled
  })

  labels = merge({
    "k3s-controller" = "ingress"
    "k3s-leader"     = "${count.index}"
  }, var.other_labels)

  depends_on = [hcloud_network_subnet.controllers]
}
resource "hcloud_server_network" "k3s_controller_network" {
  count      = var.k3s_leader_count
  server_id  = hcloud_server.k3s_controller[count.index].id
  network_id = hcloud_network.k3s_network.id
  ip         = cidrhost(hcloud_network_subnet.controllers.ip_range, 2 + count.index)
}

resource "random_password" "k3s_token" {
  length  = 48
  special = false
}

resource "hcloud_floating_ip" "k3s_controller" {
  count         = var.gateway_mode_enabled ? var.k3s_leader_count : 0
  name          = "${var.k3s_cluster_name}-controller-${count.index}"
  type          = "ipv4"
  home_location = split("-", var.datacenter)[0]
}

resource "hcloud_floating_ip_assignment" "k3s_controller" {
  count          = var.gateway_mode_enabled ? var.k3s_leader_count : 0
  floating_ip_id = hcloud_floating_ip.k3s_controller[count.index].id
  server_id      = hcloud_server.k3s_controller[count.index].id
}
