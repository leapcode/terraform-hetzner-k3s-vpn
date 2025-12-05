resource "hcloud_network" "k3s_network" {
  name     = var.k3s_cluster_name
  ip_range = "172.16.0.0/12"
}

resource "hcloud_network_subnet" "controllers" {
  network_id   = hcloud_network.k3s_network.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "172.16.0.0/24"
}

resource "hcloud_network_subnet" "workers" {
  for_each     = { for group in var.k3s_worker_nodes : group.name => group }
  network_id   = hcloud_network.k3s_network.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = cidrsubnet("172.16.0.0/16", 8, 1 + index(keys({ for group in var.k3s_worker_nodes : group.name => group }), each.key))
}
