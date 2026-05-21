# Template for a single-node gateway cluster that doesn't require an additional controller node
# Copy it to a new directory, outside of this repository.

module "k3s" {
  # Use the existing k3s module from parent directory
  source       = "git::https://0xacab.org/leap/container-platform/terraform-hetzner-k3s-vpn.git?ref=no-masters"
  hcloud_token = var.hcloud_token

  # Single node configuration
  k3s_cluster_name = "gateway-location" # ⚠️ Choose a name wrt gateway location
  k3s_leader_count = 1                  # do not change                 

  # Server configuration
  k3s_controller_server_type = "ccx11"     # ⚠️ Check if this server type is available in your chosen location or choose other server type
  k3s_base_os                = "debian-13" # do not change
  gateway_mode_enabled       = true        # do not change
  location                   = "hel1"      # ⚠️ Choose a Hetzner location name where you want to provision your resources

  # Network configuration
  k3s_network_name = "gateway-location-network" # ⚠️ Choose a name wrt gateway location

  # Admin SSH keys - you need to provide these
  admins = [ # ⚠️ Add admin ssh keys here
    # {
    #   name = "user"
    #   public_key = "ssh-ed25519 xxxxxxxxxxxxxxxxxxxxxxx"
    # }
  ]

  # No worker nodes for single node gateway setup
  k3s_worker_nodes = [] # do not change

  # Labels to tag the virtual machines in your cloud project for easy filtering in the Hetzner console.
  other_labels = { # ⚠️ Adapt or delete labels
    "owners" = "yourname"
    "env"    = "staging"
    "type"   = "gateway"
    "tier"   = "tier-label"
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
