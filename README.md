# Terraform Managed Kubernetes on Alibaba Cloud ("aliyun")

This repository contains the Terraform module for creating a simple but ready-to-use managed Kubernetes Cluster on Alibaba Cloud Container Service for Kubernetes (ACK).

It uses the latest available Kubernetes version available in the Alibaba Cloud region, creates all necessary RAM roles with its policies and generates a kubeconfig file at completion.


<p align="center">
<img alt="Alibaba Cloud Logo" width="600" height="100" src="https://upload.wikimedia.org/wikipedia/commons/4/40/Alibaba-cloud-logo-grey-2-01.png">
</p>


- [Terraform Kubernetes on Alibaba Cloud](#Terraform-Kubernetes-on-Alibaba-Cloud)
  - [Requirements](#Requirements)
  - [Features](#Features)
  - [Notes](#Notes)
  - [Defaults](#Defaults)
  - [Terraform Inputs](#Terraform-Inputs)
  - [Outputs](#Outputs)


## Requirements

You need an [Alibaba Cloud](https://portal.aws.amazon.com/gp/aws/developer/registration/index.html) account.


## Features

* Always uses latest Kubernetes version available at Alibaba Cloud region
* Creates all necessary RAM roles and policies 
* **kubeconfig** file generation


## Notes

* `export KUBECONFIG=./kubeconfig_ack` in repo root dir to use the generated kubeconfig file
* The `enable_alibaba` variable is used in the [hajowieland/terraform-kubernetes-multi-cloud](https://github.com/hajowieland/terraform-kubernetes-multi-cloud) module


## Defaults

See tables at the end for a comprehensive list of inputs and outputs.


* Default region: **eu-central-1** _(Frankfurt, Germany)_
* Default worker node type: **ecs.sn1.medium** _(2x vCPU, 4.0GB memory)_ (choose your cpu and memory configuration -> auto selection of the right instance type)
* Default worker node pool size: **2**



## Terraform Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| enable_alibaba | Enable / Disable Alibaba Cloud k8s  | bool | true | yes |
| random_cluster_suffix | Random 6 byte hex suffix for cluster name | string |  | no|
| ali_region | Alibaba Cloud region | string | eu-central-1 | no |
| ali_access_key | Alibaba Cloud access key | string |   | yes |
| ali_secret_key | Alibaba Cloud secret key | string |  | yes |
| ssh_public_key_path | Path to your existing SSH public key file | string | ~/.ssh/id_rsa.pub | no |
| ali_vpc_name | Alibaba Cloud VPC name | string | k8svpc | no |
| ali_vpc_cidr | Alibaba Cloud VPC CIDR block | string | 10.1.0.0/21 | no |
| ali_vswitch_cidrs | List of CIDR blocks used to create several new VSwitches | list(string) | 10.1.2.0/24 | no |
| ack_name | Alibaba Managed Kubernetes cluster name | string | k8s-ali | no |
| ack_node_count | Alibaba Managed Kubernetes cluster worker node count | list | 2 | no |
| ack_node_types | Alibaba node instance types for worker nodes | list(string) | ecs.sn1.medium | no |
| ack_k8s_cni | Kubernetes CNI plugin to use for networking | string | flannel | no |
| ack_k8s_pod_cidr | CIDR for Kubernetes pod network | string | 172.20.0.0/16 | no |
| ack_k8s_service_cidr | CIDR for Kubernetes service network | string | 172.21.0.0/20 | no |



## Outputs

| Name | Description |
|------|-------------|
| alicloud_eip_ip_address | Alibaba Cloud EIP IPv4 address (used for NAT gateway) |
| kubeconfig_path_oci | kubeconfig file path |
