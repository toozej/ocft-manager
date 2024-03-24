provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.30.0"
    }
  }
}

// compute VM images
data "oci_core_images" "os" {
  compartment_id           = var.compartment_id
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

// compute VM instance
resource "oci_core_instance" "vm_instance" {
  count               = var.num_instances
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_ocid
  display_name        = format("%s${count.index}", replace(title(var.instance_name), "/\\s/", ""))
  shape               = var.instance_shape

  shape_config {
    ocpus         = var.instance_ocpus
    memory_in_gbs = var.instance_memory_in_gbs
  }

  create_vnic_details {
    subnet_id                 = oci_core_subnet.vm_subnet.id
    display_name              = format("%sVNIC", replace(title(var.instance_name), "/\\s/", ""))
    assign_public_ip          = var.assign_public_ip
    assign_private_dns_record = true
    hostname_label            = format("%s${count.index}", lower(replace(var.instance_name, "/\\s/", "")))
  }

  source_details {
    source_type = var.instance_source_type
    source_id   = data.oci_core_images.os.images[0].id
	  boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_keys
    user_data           = var.user_data
  }


  lifecycle {
    ignore_changes = [
      # Ignore changes to source_details, so that instance isn't
      # recreated when a new image releases. Also allows for easy
      # resource import.
      source_details,
    ]
  }

  timeouts {
    create = "60m"
  }
}

// instance devices/disks
data "oci_core_instance_devices" "vm_instance_devices" {
  count       = var.num_instances
  instance_id = oci_core_instance.vm_instance[count.index].id
}

// VPC and networking
resource "oci_core_vcn" "vm_vcn" {
  cidr_block     = "10.0.0.0/16"
  compartment_id = var.compartment_ocid
  display_name   = format("%sVCN", replace(title(var.compartment_name), "/\\s/", ""))
  dns_label      = format("%svcn", lower(replace(var.compartment_name, "/\\s/", "")))
}

resource "oci_core_security_list" "vm_security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vm_vcn.id
  display_name   = format("%sSecurityList", replace(title(var.compartment_name), "/\\s/", ""))

  # Allow outbound traffic on all ports for all protocols
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
    stateless   = false
  }

  # Allow inbound traffic on all ports for all protocols
  ingress_security_rules {
    protocol  = "all"
    source    = "0.0.0.0/0"
    stateless = false
  }

  # Allow inbound icmp traffic of a specific type
  ingress_security_rules {
    protocol  = 1
    source    = "0.0.0.0/0"
    stateless = false

    icmp_options {
      type = 3
      code = 4
    }
  }
}

resource "oci_core_internet_gateway" "vm_internet_gateway" {
  compartment_id = var.compartment_ocid
  display_name   = format("%sIGW", replace(title(var.compartment_name), "/\\s/", ""))
  vcn_id         = oci_core_vcn.vm_vcn.id
}

resource "oci_core_default_route_table" "default_route_table" {
  manage_default_resource_id = oci_core_vcn.vm_vcn.default_route_table_id
  display_name               = "DefaultRouteTable"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.vm_internet_gateway.id
  }
}

resource "oci_core_subnet" "vm_subnet" {
  availability_domain = data.oci_identity_availability_domain.ad.name
  cidr_block          = "10.0.0.0/24"
  display_name        = format("%sSubnet", replace(title(var.compartment_name), "/\\s/", ""))
  dns_label           = format("%ssubnet", lower(replace(var.compartment_name, "/\\s/", "")))
  security_list_ids   = [oci_core_security_list.vm_security_list.id]
  compartment_id      = var.compartment_ocid
  vcn_id              = oci_core_vcn.vm_vcn.id
  route_table_id      = oci_core_vcn.vm_vcn.default_route_table_id
  dhcp_options_id     = oci_core_vcn.vm_vcn.default_dhcp_options_id
}
