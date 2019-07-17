variable "enable_alibaba" {
  description = "Enable / Disable Alibaba (e.g. `1`)"
  type        = bool
  default     = true
}

variable "random_cluster_suffix" {
  description = "Random 6 byte hex suffix for cluster name"
  type        = string
  default     = ""
}

variable "ssh_public_key_path" {
  description = "Path to your existing SSH public key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_key_pair_name" {
  description = "Name of the Alibaba Cloud Key pair"
  type        = string
  default     = "my-key-pair"
}

variable "ali_access_key" {
  description = "Alibaba Cloud access key"
  type        = string
}

variable "ali_secret_key" {
  description = "Alibaba Cloud secret key"
  type        = string
}

variable "ali_region" {
  description = "Alibaba Cloud region (e.g. `eu-central-1` => Frankfurt, Germany)"
  type        = string
  default     = "eu-central-1"
}

variable "ali_vpc_name" {
  description = "The vpc name used to create a new vpc when 'vpc_id' is not specified. Default to variable `example_name`"
  default     = ""
}

variable "ali_vpc_cidr" {
  description = "The cidr block used to launch a new vpc when 'vpc_id' is not specified."
  default     = "10.1.0.0/21"
}

variable "ali_vswitch_cidrs" {
  description = "List of cidr blocks used to create several new vswitches when 'vswitch_ids' is not specified."
  type        = "list"
  default     = ["10.1.2.0/24"]
}

variable "ack_name" {
  description = "Alibaba Managed Kubernetes cluster name (e.g. `k8s-ali`)"
  type        = string
  default     = "k8s-ali"
}

variable "ack_node_count" {
  description = "Alibaba Managed Kubernetes cluster worker node count (e.g. `[2]`)"
  type        = list
  default     = [2]
}

variable "ack_node_type" {
  description = "Alibaba node instance type for worker nodes (e.g. `ecs.sn1.medium` => 2x vCPU 4GB memory)"
  type        = string
  default     = "ecs.sn1.medium"
}

variable "ack_worker_system_disk_category" {
  description = "System disk category of worker nodes (e.g. `cloud_efficiency` or `cloud_ssd`)"
  type        = string
  default     = "cloud_efficiency"
}

variable "ack_worker_system_disk_size" {
  description = "System disk size of worker nodes (min.: `20` max: `32768`)"
  type        = number
  default     = 20
}

variable "ack_worker_data_disk_category" {
  description = "Data disk category of worker nodes (e.g. `cloud_efficiency` or `cloud_ssd`)"
  type        = string
  default     = "cloud_efficiency"
}

variable "ack_worker_data_disk_size" {
  description = "Data disk size of worker nodes (min.: `20` max: `32768`)"
  type        = number
  default     = 20
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