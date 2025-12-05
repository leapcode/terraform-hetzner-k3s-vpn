output "k3s_controller_ip" {
  value = hcloud_server.k3s_controller[0].ipv4_address
}

output "message" {
  value = <<EOT
Provisioning k3s infra is done!
Try ssh to root@${hcloud_server.k3s_controller[0].ipv4_address}, and make sure you have admin access
Now you can create an alias to easily run kubectl commands locally: alias kr="ssh root@${hcloud_server.k3s_controller[0].ipv4_address} kubectl" 
After setting this alias, you can execute kubectl commands remotely by running, kr get nodes -o wide
Note that with this setup, you cannot edit resources interactively or apply local YAML files, 
since the commands are executed on the remote server and do not have access to your local files.
EOT
}
