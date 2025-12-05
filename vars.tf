variable "k3s_cluster_name" {
  type        = string
  default     = "k3s-leap"
  description = "Name of the cluster"
}

variable "k3s_network_name" {
  type        = string
  default     = "k3s-leap"
  description = "Name of the network to be created for the k3s cluster"

}

variable "k3s_version" {
  type        = string
  default     = "v1.32.5+k3s1"
  description = "Version of K3s to download from Github"

}

variable "k3s_url" {
  type        = string
  default     = ""
  description = "The K3S leader URL for agent nodes (leave empty for leader node)"
}

variable "k3s_leader_count" {
  type        = number
  default     = 1
  description = "Number of leader nodes. Must be an odd number."

  validation {
    condition     = var.k3s_leader_count % 2 == 1
    error_message = "Invalid value for k3s_leader_count. It must be an odd number (e.g. 1, 3, 5)."
  }
}

variable "k3s_controller_server_type" {
  type        = string
  default     = "cpx11"
  description = "Choose one from https://www.hetzner.com/cloud/#pricing"

  validation {
    # validating the availability of the controller server type in the configured datacenter
    condition = (
      contains(lookup(local.datacenter_map, var.datacenter, { server_types = [] }).server_types, var.k3s_controller_server_type)
    )

    error_message = format("Invalid value for k3s_controller_server_type at datacenter %s. \n\nAllowed values for k3s_controller_server_type: %v\n\nSet value for k3s_controller_server_type: %s",
      var.datacenter,
      lookup(local.datacenter_map, var.datacenter, { server_types = [] }).server_types,
      var.k3s_controller_server_type
    )
  }
}

# https://docs.hetzner.com/cloud/general/locations/
variable "datacenter" {
  type        = string
  description = "Hetzner datacenter name (e.g., hel1-dc2)."
  default     = "hel1-dc2"

  validation {
    # validating the existence of the data center name
    condition = lookup(local.datacenter_map, var.datacenter, null) != null

    error_message = format("Invalid value for datacenter.\n\nAllowed values for datacenter: %v.\n\nSet value for datacenter: %s",
      keys(local.datacenter_map),
      var.datacenter
    )
  }
}

variable "k3s_gateway_server_type" {
  type        = string
  default     = "cx23"
  description = "Choose one from https://www.hetzner.com/cloud/#pricing"
}

variable "k3s_backend_server_type" {
  type        = string
  default     = "cax11"
  description = "Choose one from https://www.hetzner.com/cloud/#pricing"
}

variable "k3s_worker_nodes" {
  description = <<-EOF
  List of k3s worker group definitions.

  Each object has:
  - name (string): logical group name for the worker nodes, e.g. gateway or backend.
  - count (number): desired number of nodes in the group.
  - server_type (optional string): instance/size type, e.g., "cx23", see https://www.hetzner.com/cloud/. If omitted and the name field is either "gateway", "monitoring", "menshen" or "backend", defaults are set.
  - image (optional string): image id or name to use. If omitted a default image is used.
  - ssh_keys (optional list(string)): list of SSH public key IDs or fingerprints to attach.
  - admins (optional list(string)): list of admin usernames.
  - labels (map(string)): Kubernetes node labels to apply to each node in the group.
  - user_data (optional string): cloud-init or startup script.
  EOF
  type = list(object({
    name        = string
    count       = number
    server_type = optional(string)
    image       = optional(string)
    ssh_keys    = optional(list(string))
    admins      = optional(list(string))
    labels      = optional(map(string))
    user_data   = optional(string)
  }))

  validation {
    # validating the availability of the node's server type in the given data center
    condition = alltrue([
      for node in var.k3s_worker_nodes :
      # case 1: validating server_type defaults
      (
        # verify that server_type is null
        node.server_type == null &&
        # verify that node name is mapped to a default server_type
        lookup(local.default_server_types_map, node.name, null) != null &&
        # verify that the datacenter supports the default server_type
        contains(
          lookup(local.datacenter_map, var.datacenter, { server_types = [] }).server_types,
        local.default_server_types_map[node.name].server_type)
      )
      ||
      # case 2: validating given server_type string
      (
        # verify that server_type is not null
        node.server_type != null &&
        # verify that the datacenter supports the given server_type
        contains(
          lookup(local.datacenter_map, var.datacenter, { server_types = [] }).server_types,
          node.server_type
        )
      )
    ])

    error_message = format("Invalid k3s_worker_nodes server_type at datacenter %s.\n\nAllowed values for server_type:\n%v\n\nAllowed node names with automatically assigned defaults: \n%v\n\nSet values for server_type:\n%v",
      var.datacenter,
      lookup(local.datacenter_map, var.datacenter, { server_types = [] }).server_types,
      local.default_server_types_map,
      [
        for node in var.k3s_worker_nodes : {
          name        = node.name
          server_type = node.server_type
        }
      ]
    )
  }
}

variable "k3s_base_os" {
  type        = string
  default     = "debian-12"
  description = "Choose the debian version(we have only tested on debian 12)"
}

variable "network_zone" {
  type        = string
  default     = "eu-central"
  description = "Name of network zone."

}

variable "gateway_mode_enabled" {
  description = "Set to true to enable gateway, false to disable."
  type        = bool
  default     = false
}

variable "other_labels" {
  type = map(string)
  default = {
    "owner" = "leap"
    "env"   = "demo"
  }
  description = "Other labels for vm's"

}

variable "admins" {
  type = list(object({
    name       = string
    public_key = string
  }))
  description = "List of admin SSH keys"
}

variable "hcloud_token" {
  type        = string
  sensitive   = true
  description = "Hetzner API token, needs to have Read and Write access"
}