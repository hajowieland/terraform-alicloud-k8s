# output "kubeconfig_path_ack" {
#   value = "${local_file.kubeconfigack.0.filename}"
# }

output "alicloud_eip_ip_address" {
  value = alicloud_eip.eip.0.ip_address
}