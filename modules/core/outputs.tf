output "instance_private_ips" {
  value = [oci_core_instance.vm_instance.*.private_ip]
}

output "instance_public_ips" {
  value = [oci_core_instance.vm_instance.*.public_ip]
}

output "boot_volume_ids" {
  value = [oci_core_instance.vm_instance.*.boot_volume_id]
}

output "instance_devices" {
  value = [data.oci_core_instance_devices.vm_instance_devices.*.devices]
}
