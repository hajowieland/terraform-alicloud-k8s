output "alicloud_eip_ip_address" {
  value = alicloud_eip.eip.0.ip_address
}

output "kubeconfig_path_ali" {
  value = alicloud_cs_managed_kubernetes.ack.0.kube_config
}
