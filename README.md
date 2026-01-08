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

  2. Provide important variables

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

This method allows provisioning from your local machine to remotes.
If not done before, copy the directory `terraform-k3s/hetzner/examples/scripts` to your work directory and run within the work directory:
```bash
eval $(./scripts/access_cluster.sh --start)
```
Calling this script like described above will pull the k3s.yml from your controller node, adapt it for use on localhost, create in a background process a ssh tunnel with port forwarding on port 6443 to your controller node and automatically export the `KUBECONFIG` environment variable to your current shell.

You can also use the script to access a cluster that you have ssh-access to but that you haven't provisioned yourself. If there is no **terraform.tfstate** file in the parent directory you will be prompted for the public IP address of your controller node.

If you have provisioned your cluster with a different SSH key than your default one, you can amend `--ssh-key <path/to/your/ssh-key` to the command:

```bash
eval $(./scripts/access_cluster.sh --start --ssh-key <path/to/your/ssh-key>)
```

Test the kubectl commands using the following command (if you haven’t yet installed kubectl on your local machine, follow this guide: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/). This should return a table with your deployed nodes.

```bash
kubectl get nodes -o wide
```

If you want to run kubectl in a different shell then the one you've used to start port forwarding just export there the KUBECONFIG:

```bash
export KUBECONFIG=<path-to-your-work-dir>/k3s-local.yaml
```

### Stopping port forwarding
Once you're done with your work, you should close your ssh session to your controller node and disable port forwarding again. This can be done by running

```bash
./scripts/portforwarding.sh --stop
```

### Some useful `kubectl` commands
#### list all nodes and wide output
```bash
kubectl get nodes -o wide
```

#### list all pods in all namespaces
```bash
kubectl get pods -A -o wide
```
