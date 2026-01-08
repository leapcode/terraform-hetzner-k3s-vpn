# Template for a multi-node cluster for backend components
# Copy it to a new directory, outside of this repository.

module "k3s" {
  source       = "git::https://0xacab.org/leap/container-platform/terraform-hetzner-k3s-vpn.git?ref=no-masters"
  hcloud_token = var.hcloud_token

  # Cluster name
  k3s_cluster_name = "backend-cluster"

  # Network configuration
  k3s_network_name = "backend-cluster"

  # List of your worker nodes. (Your controller node will be created automatically)
  # Check terraform-k3s/hetzner/vars.tf to see all available properties of
  # the k3s_worker_node object
  k3s_worker_nodes = [
    {
      name  = "menshen"
      count = 1
      labels = {
        "workload" = "menshen"
      }
    },
    {
      name  = "monitoring"
      count = 1
      labels = {
        "workload" = "monitoring"
      }
    }
  ]

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