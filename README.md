# Overview

A Terraform module to provision a minimal k3s Kubernetes cluster tailored to LEAP's VPN stack on Hetzner Cloud.

## Features

- Deploys a minimal k3s cluster
- Uses Hetzner Cloud resources (servers, networks)
- Automated provisioning via Terraform
- Private networking between nodes
- Easily extensible for more nodes or features

## Backend cluster architecture

We propose the following setup of services across worker nodes:

**k3s controller node (backend, reverse-proxy):**

- Ingress : Traefik
- cert-manager (https://cert-manager.io/) and other kube-master components

**k3s worker node 1 (menshen):**

- menshen
- invitectl to add invite codes to db menshen depends on

**k3s worker node 2: (monitoring):**

- [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) including
- Prometheus
- Grafana

# Provisioning on Hetzner Cloud

## 1. Creating a Public Cloud project on Hetzner

Follow these steps to set up your project:

1. Create a Hetzner Account on https://www.hetzner.com/ and log in.
2. Create a new project: on the dashboard, click `New Project`, enter a name and click `Add project`.

## 2. Configuring your project

It's easiest to start with the template files for backend and gateway cluster located under `hetzner/examples`. These files contain:

1. The necessary code to import this repository as a Terraform module.
2. All required variables for a basic setup.

Just copy the whole `hetzner/exmaples` directory to a directory you wish (your working directory) and adapt the Terraform examples.

### 2.1 Ensuring Git access

Make sure you have access to the git repo and can git clone it, otherwise Terraform initialization will fail.
Alternatively you can use the ssh-method to clone the repo during the init-process by replacing the `source = ...` line by `source = "git::ssh://git@0xacab.org/leap/container-platform/terraform-k3s.git"`

### 2.2 Providing important variables

In your template file you can choose how many and which servers you want to provision in which location. It is important to first check which server types are available in which region. It is easiest to achieve this by navigating to your cloud project in the Hetzner console and pretending to want to create a server by clicking through the interface. Go to _Servers_ on the top of the left navigation bar and click "Add Server". There you can see all current locations with their codes and server types available in them. Choose only servers with 'x86' architecture. You need to fill in the server names in the template file.

Below is a list of the variables you should provide in your config:
| Variable | Type | Description |
| --------- | ---- | --------- |
| _k3s_cluster_name_ | string | The name for your k3s cluster. |
| _k3s_leader_count_ | number | The number of leader nodes. Must be odd. Except for corner cases where you want to provision a multi-leader cluster, 1 is fine. |
| _k3s_controller_server_type_ | string | The hetzner server code for controller nodes. Choose one from https://www.hetzner.com/cloud/#pricing, only choose Intel/AMD machines." |
| _k3s_base_os_ | string | The name of the operating system to install on all controller nodes and the default for worker nodes. We only tested on "Debian 13". |
| _gateway_mode_enabled_ |boolean | Set to true if you want to provision a gateway cluster, false for backend. Defaults to false. |
| _location_ | string | Hetzner location name (e.g. hel1 for Helsinki). Choose one from https://docs.hetzner.com/cloud/general/locations but make sure the chosen server type is available at the chosen location.|
| _k3s_network_name_ | string | Name for the network. |
| _admins_ | list(object({ name = string, public_key = string })) | List of admin SSH key objects containing a freely selectable name and a corresponding public ssh key. |
| _k3s_worker_nodes_ | list(object({ name = string, count = number, server_type = optional string, image = optional string, labels = optional map(string) })) | A list of groups of worker nodes, each sharing a common operating system and server flavor. The variable _count_ determines how many nodes of this kind you want to spin up. The _image_ defaults to the value of _k3s_base_os_. In a single-node cluster like a gateway this variable should be [] as there is only one controller node and no worker nodes. See [vars.tf](https://0xacab.org/leap/container-platform/terraform-hetzner-k3s-vpn/-/blob/no-masters/vars.tf#L106-129) for more configuration options. |
| _other_labels_ | map(string) | Labels to tag the virtual machines in your cloud project for easy filtering in the Hetzner console. Both key and value must be 63 characters or less, beginning and ending with an alphanumeric character and alphanumerics can be used inbetween. |

## 3. Creating and providing a Hetzner API token for your project

First you need to generate a Read-Write token for your project in order to create and delete resources with Terraform. Enter your new project in the Hetzner console and navigate to `Security` settings (left sidebar, bottom).
Go to the `API tokens` tab and click `Generate API token`. Make sure to activate `Read & Write` permissions. Store the generated token securily. It is only shown once in the web interface.

In order to provide this API token to Terraform you can use an environment variable. Open a shell, fill in your newly created token and run:

```bash
export TF_VAR_hcloud_token=<your-API-token>
```

## 4. Provisioning the resources using Terraform

### 4.1 Initializing Terraform

In the same shell and in the folder with your Terraform project file, run

```
terraform init
```

This initializes a working directory containing Terraform configuration files.

### 4.2 Planning

When everything works out run

```
terraform plan
```

This creates an execution plan, which lets you preview the changes that Terraform plans to make to your infrastructure.Read the plan and make sure things are getting created as expected.

### 4.3 Applying

Last run

```
terraform apply
```

This executes the actions proposed in the Terraform plan to create, update, or destroy infrastructure. Your k3s cluster is now being provisioned. 🎊

You can check on the Hetzner Cloud Console Dashboard if all of your resources are created as expected.

## 5. Accessing the cluster using port forwarding

The [podlily](https://0xacab.org/leap/container-platform/podlily) repository contains a script `access_cluster.sh` that can be used to port-forward into the cluster. This method also allows provisioning from your local machine to remotes. Copy the script into this directory to use it. You can find more information on the script in its documentation that is also part of podlily.
