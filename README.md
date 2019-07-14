# Terraform Kubernetes on Alibaba Cloud

This repository contains the Terraform module for creating a simple but ready-to-use Kubernetes Cluster on Alibaba Cloud Container Service for Kubernetes (ACK).

It uses the latest available Kubernetes version available in the Alibaba Cloud region and creates a kubeconfig file at completion.


- [Terraform Kubernetes on Alibaba Cloud](#Terraform-Kubernetes-on-Alibaba-Cloud)
  - [Requirements](#Requirements)
  - [Features](#Features)
  - [Notes](#Notes)
  - [Defaults](#Defaults)
  - [Runtime](#Runtime)
  - [Terraform Inputs](#Terraform-Inputs)
  - [Outputs](#Outputs)


## Requirements

You need an [Alibaba Cloud](https://portal.aws.amazon.com/gp/aws/developer/registration/index.html) account.


## Features

* Always uses latest Kubernetes version available at AWS region
* **kubeconfig** file generation
* Auto selects the right instance type for your CPU and memory configuration (`ali_node_type_cpu` and `ali_node_type_memory`)
* Authentication via AWS IAM with [aws-iam-authenticator](https://github.com/kubernetes-sigs/aws-iam-authenticator) (for Linux and macOS)
* Kubernetes cluster API access is available from workstation IP address only
* Auto Scaling Group for worker nodes


## Notes

* `export KUBECONFIG=./kubeconfig_ack` in repo root dir to use the generated kubeconfig file
* Auto Downloads **aws-iam-authenticator** executable for AWS IAM Kubernetes authorization (Linux & macOS)
* The `enable_alibaba` variable is used in the [hajowieland/terraform-kubernetes-multi-cloud](https://github.com/hajowieland/terraform-kubernetes-multi-cloud) module


## Defaults

See tables at the end for a comprehensive list of inputs and outputs.


* Default region: **eu-central-1** _(Frankfurt, Germany)_
* Default node type: **ecs.sn1.medium** _(2x vCPU, 4.0GB memory)_ (choose your cpu and memory configuration -> auto selection of the right instance type)
* Default worker system disk size is **20GB**
* Default worker data disk size is **20GB**
* Default node pool size: **2**


## Runtime

`terraform apply`:

~10-11min

```
7.44s user
4.09s system
10:39.68 total
```

```
7.86s user
4.51s system
10:57.32 total
```

```
7.42s user
3.98s system
11:11.69 total
```


## Terraform Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| enable_amazon | Enable / Disable Amazon Web Services k8s | bool | true | yes |
| random_cluster_suffix | Random 6 byte hex suffix for cluster name | string |  | true |
| aws_region | AWS region | string | eu-central-1 | yes |
| aws_profile | AWS cli profile | string | default | yes |
| eks_nodes | EKS Kubernetes worker nodes, desired ASG capacity | number | 2 | yes |
| eks_min_nodes | EKS Kubernetes worker nodes, minimal ASG capacity | number | 1 | yes |
| eks_max_nodes | EKS Kubernetes worker nodes, maximal ASG capacity | number | 3 | yes |
| aws_cidr_block | AWS VPC CIDR block | string | 10.0.0.0/16 | yes |
| aws_subnets | List of 8-bit numbers of subnets base_cidr_block | number | 2 | yes |
| aws_cluster_name | AWS ELS cluster name | string | k8s-eks | yes |
| aws_instance_type | AWS EC2 Instance Type| string | t3.medium | yes |



## Outputs

| Name | Description |
|------|-------------|
| kubeconfig_path_aws | Kubernetes kubeconfig file |
| config_map_aws_auth | Kubernetes ConfigMap for aws authentication |
