# Template for a single-node gateway cluster that doesn't require an additional controller node
# Copy it to a new directory, outside of this repository.

# Use the existing k3s module from parent directory
module "k3s" {
  source       = "git::https://0xacab.org/leap/container-platform/terraform-k3s.git//hetzner?ref=no-masters"
  hcloud_token = var.hcloud_token

  # Cluster name
  k3s_cluster_name = "k3s-gateway"

  # Server configuration
  # required to be set to true, do not change
  gateway_mode_enabled = true

  # Network configuration
  k3s_network_name = "k3s-gateway-network"

  # Optionally set the data center and the server, there are defaults set in vars.tf
  #
  # k3s_controller_datacenter = <set-data-center>
  # k3s_controller_server_type = <set-server-type>

  # No worker nodes for single node gateway setup
  k3s_worker_nodes = [] # do not change

  # Admin SSH keys - you'll need to provide these
  admins = [
    {
      name       = "<your_admin_name>"
      public_key = "<your_public_ssh_key>"
    }
  ]

  # Labels are key/value pairs and used to tag the virtual machines in hetzner
  # Useful to filter them in the hetzner cloud console
  # Both key and value must be 63 characters or less, 
  # beginning and ending with an alphanumeric character and 
  # alphanumerics can be used inbetween
  other_labels = {
    "owners" = "yourname"
    "env"    = "staging"
    "type"   = "gateway"
    "tier"   = "cost-optimized"
  }
}

# Hetzner Read-Write API token, provide externally e.g. via 
# export TF_VAR_hcloud_token=<your-api-token> or via 
# your terrform.tfvars file 
variable "hcloud_token" {
  sensitive = true
} # do not change

output "k3s_controller_ip" {
  value = module.k3s.k3s_controller_ip
}