#!/bin/bash

apt-get -yq update
apt-get install -yq \
    ca-certificates \
    curl \
    ntpsec \
    open-iscsi \
    grep 

PUBLIC_IP=$(curl http://169.254.169.254/hetzner/v1/metadata/public-ipv4|sed 's/\/32//')
PRIVATE_IP=${private_ip}
FLOATING_IP=${floating_ip}
CLUSTER_CIDR=${cluster_cidr}
SERVICE_CIDR=${service_cidr}
CLUSTER_DNS=${cluster_dns}

export K3S_TOKEN=${k3s_token} 
export INSTALL_K3S_EXEC="--node-ip $PRIVATE_IP \
  --node-external-ip $PUBLIC_IP"

if [[ -z "${k3s_url}" ]]; then
  echo "K3S_URL is empty, continuing as controller node"
    # disable traefik installation via k3s installer 
    export INSTALL_K3S_EXEC="$INSTALL_K3S_EXEC \
        --disable=traefik \
        --cluster-cidr $CLUSTER_CIDR \
        --service-cidr $SERVICE_CIDR \
        --cluster-dns $CLUSTER_DNS"

  if [ "${total_leaders}" -eq 1 ]; then
    # single leader cluster
    echo "Single leader cluster"
  else
    if [ "${leader_count}" -eq 0 ]; then
      # multimaster setup init leader 
      export INSTALL_K3S_EXEC="$INSTALL_K3S_EXEC \
      --cluster-init"
    else
      # multimaster setup init followers
      export INSTALL_K3S_EXEC="$INSTALL_K3S_EXEC \
      --server https://172.16.0.2:6443 " #FIXME : Fix hardcoded IP for hcloud_server_network.k3s_controller_network[0].ip
    fi
  fi
  export INSTALL_K3S_EXEC="$INSTALL_K3S_EXEC \
  --bind-address $PRIVATE_IP \
  --advertise-address $PRIVATE_IP"
else
  export K3S_URL="https://${k3s_url}:6443"
  echo "K3S_URL is set to: ${k3s_url}, continuing as worker node"
fi

if ${gateway_mode_enabled}; then
 #install and load ovpn-dco module Ref: https://github.com/OpenVPN/ovpn-dco
 apt install -yq openvpn-dco-dkms dkms linux-headers-$(uname -r)
 modprobe ovpn-dco-v2
 # flags for gateway
 export INSTALL_K3S_EXEC="$INSTALL_K3S_EXEC \
 --kubelet-arg=allowed-unsafe-sysctls=net.ipv4.ip_forward"
fi

# k3s installation
curl -sfL https://get.k3s.io | sh -s - \
    --kubelet-arg 'cloud-provider=external'

# secondary_ip configuration for gateways
if [ -n "$FLOATING_IP" ]; then
  ip addr add "$FLOATING_IP/32" dev eth0
  iptables -t nat -I POSTROUTING 1 -s 10.42.0.0/24 -o eth0 -j SNAT --to-source "$FLOATING_IP"
  echo "Floating IP configured: $FLOATING_IP"
fi
