locals {
  # Get all SSH key IDs of admins for easy reference
  admin_ssh_key_ids = [for admin in var.admins : try(hcloud_ssh_key.admins[admin.name].id, [for k in data.hcloud_ssh_keys.all.ssh_keys : k.id if k.name == admin.name][0])]

  group_server_types_map = {
    for group in var.k3s_worker_nodes :
    group.name => (
      group.server_type != null ? group.server_type :
      lookup(local.default_server_types_map, group.name, { server_type = null }).server_type
    )
  }

  default_server_types_map = {
    gateway = {
      server_type = var.k3s_gateway_server_type
    }
    menshen = {
      server_type = var.k3s_backend_server_type
    }
    monitoring = {
      server_type = var.k3s_backend_server_type
    }
    backend = {
      server_type = var.k3s_backend_server_type
    }
  }

  # Expand each group into a flat list of VMs with unique names
  # Defaults for server_type are set here.
  k3s_worker_nodes = flatten([
    for group in var.k3s_worker_nodes : [
      for i in range(group.count) : {
        name        = "${group.name}-${i}"
        group_name  = group.name
        server_type = local.group_server_types_map[group.name]
        image       = group.image != null ? group.image : var.k3s_base_os
        ssh_keys    = local.admin_ssh_key_ids,
        labels      = group.labels != null ? group.labels : {}
        user_data   = lookup(group, "user_data", null)
      }
    ]
  ])

  location_map = {
    for loc in data.hcloud_locations.all.locations :
    loc.name => {
      name    = loc.name
      city    = try(loc.city, "unknown")
      country = try(loc.country, "unknown")
      server_types = compact([
        for st in data.hcloud_server_types.all.server_types :
        st.name if anytrue([
          for l in st.locations : l.available && l.name == loc.name
        ])
      ])
    }
  }

  server_type_map = {
    for st in data.hcloud_server_types.all.server_types :
    st.name => {
      name         = st.name
      id           = st.id
      architecture = st.architecture
      cores        = st.cores
      cpu_type     = st.cpu_type
      memory       = st.memory
      disk         = st.disk
    }
  }

  k3s_worker_nodes_gateway = var.gateway_mode_enabled ? { for idx, node in local.k3s_worker_nodes : node.name => node } : {}

}
