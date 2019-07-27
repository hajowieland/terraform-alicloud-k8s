variable "enable_alibaba" {
  description = "Enable / Disable Alibaba Cloud k8s (e.g. `true`)"
  type        = bool
  default     = true
}

variable "random_cluster_suffix" {
  description = "Random 6 byte hex suffix for cluster name"
  type        = string
  default     = ""
}

variable "ali_region" {
  description = "Alibaba Cloud region (e.g. `eu-central-1` => Frankfurt, Germany)"
  type        = string
  default     = "eu-central-1"
}

variable "ali_access_key" {
  description = "Alibaba Cloud access key"
  type        = string
}

variable "ali_secret_key" {
  description = "Alibaba Cloud secret key"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to your existing SSH public key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ali_vpc_name" {
  description = "Alibaba Cloud VPC name"
  default     = "k8svpc"
}

variable "ali_vpc_cidr" {
  description = "Alibaba Cloud VPC CIDR block"
  default     = "10.1.0.0/21"
}

variable "ali_vswitch_cidrs" {
  description = "List of CIDR blocks used to create several new VSwitches"
  type        = list(string)
  default     = ["10.1.2.0/24"]
}

variable "ack_name" {
  description = "Alibaba Managed Kubernetes cluster name (e.g. `k8s-ali`)"
  type        = string
  default     = "k8s-ali"
}

variable "ack_node_count" {
  description = "Alibaba Managed Kubernetes cluster worker node count (e.g. `[2]`)"
  type        = number
  default     = 2
}

variable "ack_node_type" {
  description = "Alibaba node instance type for worker nodes (e.g. `ecs.sn1.medium` => 2x vCPU 4GB memory)"
  type        = string
  default     = "ecs.sn1.medium"
}

variable "ack_k8s_cni" {
  description = "Kubernetes CNI plugin to use for networking (e.g. `flannel` or `terway`)"
  type        = string
  default     = "flannel"
}

variable "ack_k8s_pod_cidr" {
  description = "CIDR for Kubernetes pod network"
  type        = string
  default     = "172.20.0.0/16"
}

variable "ack_k8s_service_cidr" {
  description = "CIDR for Kubernetes service network"
  type        = string
  default     = "172.21.0.0/20"
}