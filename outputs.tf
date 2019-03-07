output "instanceName" {value = "${oci_core_instance.CreateInstance.display_name}"}
output "instancePublicIP" {value = "${oci_core_instance.CreateInstance.public_ip}"}
output "instancePrivateIP" {value = "${oci_core_instance.CreateInstance.private_ip}"}


