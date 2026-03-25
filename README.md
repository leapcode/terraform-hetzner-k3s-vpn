# Overview

A Terraform module to provision a minimal k3s Kubernetes cluster tailored to LEAP's VPN stack on Hetzner Cloud.

## Features

* Deploys a minimal k3s cluster
* Uses Hetzner Cloud resources (servers, networks)
* Automated provisioning via Terraform
* Private networking between nodes
* Easily extensible for more nodes or features

## Architecture

We propose the following setup of services across worker nodes:

**k3s controller node (reverse-proxy):**
* Ingress : Traefik
* cert-manager (https://cert-manager.io/) and other kube-master components

**k3s worker node 1 (backend):**
* menshen
* invitectl to add invite codes to db menshen depends on 

**k3s worker node 2: (monitoring, logs):**
* [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) including
* prometheus
* grafana


# Provisioning on Hetzner Cloud

## 1. Create a public cloud project and API token on Hetzner

Follow these steps to set up your project and generate the required API token.

1. Create a Hetzner Account and Log in.
2. Create a new project: on the Dashboard, click `New Project`, enter a name and click `Add project`.
3. Generate a Read-Write token. Enter the new project and navigate to `Security` settings (left sidebar, bottom).
Go to the `API tokens` tab and click `Generate API token`. Store the generated token securily. It is only shown once in the web interface.

## 2. Configure your project

It's easiest to start with the template directory located under `hetzner/examples`. This directory contains:
1. The necessary code to import this repository as a Terraform module.
2. All required variables for a basic setup.
3. A helper script for accessing your cluster from your local machine.

Just copy the whole `hetzner/exmaples` directory to a directory you wish (your working directory) and adapt the terraform examples.

### 2.1 Ensure Git access

Make sure you have access to the git repo and can git clone it, otherwise terraform initialization will fail.
Alternatively you can use the ssh-method to clone the repo during the init-process by replacing the `source = ...`  line by `source = "git::ssh://git@0xacab.org/leap/container-platform/terraform-k3s.git"`

### 2.2 Provide important variables

Below is a list of the variables you ***must*** provide in your config:
| Variable | Type | Description |
| --------- | ---- | --------- |
| *hcloud_token* | string | The Hetzner Cloud API token created Step 1 | 
| *admins* | [list(object)](./vars.tf) | list of admin objects, containing a name and the corresponding public ssh key. See [vars.tf](vars.tf) for details |
| *k3s_worker_nodes* | list(object) | A list of worker nodes. Default to one backend and one gateway node. Search for `k3s_worker_nodes` in [vars.tf](vars.tf) for a objects properties |

## 3. Provision the resources

### 3.1 Initialize terraform
In the same shell and in the folder with your terraform project file, run 
```
terraform init
``` 
### 3.2 Run
When everything works out run 
```
terraform plan
```
Read the plan and make sure things are getting created as expected.

### 3.3 Apply
Last run 
```
terraform apply
```
Your k3s cluster is now being provisioned. 🎊\
You can check on the Hetzner cloud console dashboard if all of your resources are created as expected.

## 4. Accessing the cluster using port forwarding

The [podlily](https://0xacab.org/leap/container-platform/podlily) repository contains a script `access_cluster.sh` that can be used to port-forward into the cluster. This method also allows provisioning from your local machine to remotes. Copy the script into this directory to use it. You can find more information on the script in its documentation that is also part of podlily.