# Template for a multi-node cluster for backend components
# Copy it to a new directory, outside of this repository.

module "k3s" {
  # Use the existing k3s module from parent directory
  source       = "git::https://0xacab.org/leap/container-platform/terraform-hetzner-k3s-vpn.git?ref=no-masters"
  hcloud_token = var.hcloud_token

  # Cluster name
  k3s_cluster_name = "backend-cluster"
  k3s_leader_count = 1

  # Server configuration
  k3s_controller_server_type = "ccx13"     # ⚠️ Check if this server type is available in your chosen location or choose other server type
  k3s_base_os                = "debian-13" # do not change
  gateway_mode_enabled       = false       # do not change
  location                   = "hel1"      # ⚠️ Choose a Hetzner location name where you want to provision your resources

  # Network configuration
  k3s_network_name = "backend-cluster"

  # Admin SSH keys - you'll need to provide these
  admins = [ # ⚠️ Add admin ssh keys here!
    {
      name       = "<your_admin_name>"
      public_key = "<your_public_ssh_key>"
    }
  ]

  # Setup with two worker nodes
  # Check vars.tf to see all available properties of the k3s_worker_nodes object
  k3s_worker_nodes = [
    {
      name        = "menshen"
      count       = 1
      server_type = "ccx13" # ⚠️ Check if this server type is available in your chosen location or choose other server type
      image       = "debian-13"
      labels = {
        "workload" = "menshen"
      }
    },
    {
      name        = "monitoring"
      count       = 1
      server_type = "ccx13" # ⚠️ Check if this server type is available in your chosen location or choose other server type
      image       = "debian-13"
      labels = {
        "workload" = "monitoring"
      }
    }
  ]

  # Labels to tag the virtual machines in your cloud project for easy filtering in the Hetzner console.
  other_labels = { # ⚠️ Adapt or delete labels
    "owners"  = "your-name"
    "env"     = "staging"
    "purpose" = "demo_can_be_deleted"
    "type"    = "backend"
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
