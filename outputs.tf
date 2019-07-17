output "alicloud_eip_ip_address" {
  value = alicloud_eip.eip.0.ip_address
}