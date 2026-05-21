# k3s workers
resource "hcloud_server" "k3s_worker" {
  for_each    = { for idx, node in local.k3s_worker_nodes : node.name => node }
  name        = "${var.k3s_cluster_name}-${each.key}"
  server_type = each.value.server_type
  image       = each.value.image
  ssh_keys    = each.value.ssh_keys
  location  = var.location

  user_data = templatefile("${path.module}/templates/cloud-init.sh", {
    k3s_token            = random_password.k3s_token.result,
    k3s_url              = hcloud_server_network.k3s_controller_network[0].ip,
    leader_count         = ""
    total_leaders        = ""
    private_ip           = cidrhost(hcloud_network_subnet.workers[each.value.group_name].ip_range, 2 + index([for node in local.k3s_worker_nodes : node.name if node.group_name == each.value.group_name], each.key))
    floating_ip          = var.gateway_mode_enabled ? hcloud_floating_ip.k3s_worker[each.key].ip_address : ""
    gateway_mode_enabled = var.gateway_mode_enabled
    cluster_cidr         = ""
    service_cidr         = ""
    cluster_dns          = ""
  })

  labels = merge({
    "cluster-name" = var.k3s_cluster_name
  }, each.value.labels, var.other_labels)

  depends_on = [hcloud_server.k3s_controller]
}

resource "hcloud_server_network" "k3s_worker_network" {
  for_each   = { for idx, node in local.k3s_worker_nodes : node.name => node }
  server_id  = hcloud_server.k3s_worker[each.key].id
  network_id = hcloud_network.k3s_network.id
  ip         = cidrhost(hcloud_network_subnet.workers[each.value.group_name].ip_range, 2 + index([for node in local.k3s_worker_nodes : node.name if node.group_name == each.value.group_name], each.key))
}

resource "hcloud_floating_ip" "k3s_worker" {
  for_each      = local.k3s_worker_nodes_gateway # Empty map when gateway_mode_enabled = false
  name          = "${var.k3s_cluster_name}-${each.key}"
  type          = "ipv4"
  home_location = var.location
}

resource "hcloud_floating_ip_assignment" "k3s_worker" {
  for_each       = local.k3s_worker_nodes_gateway # Empty map when gateway_mode_enabled = false
  floating_ip_id = hcloud_floating_ip.k3s_worker[each.key].id
  server_id      = hcloud_server.k3s_worker[each.key].id
}
