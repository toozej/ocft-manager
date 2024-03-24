variable "fingerprint" {
  description = "Fingerprint of oci api private key"
  type        = string
}

variable "private_key_path" {
  description = "Path to oci api private key used"
  type        = string
}

variable "region" {
  description = "The oci region where resources will be created"
  type        = string
}

// https://docs.oracle.com/en-us/iaas/Content/General/Concepts/identifiers.htm#tenancy_ocid
variable "tenancy_ocid" {
  description = "Tenancy ocid where to create the sources"
  type        = string
}

// https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm#five
variable "user_ocid" {
  description = "Ocid of user that terraform will use to create the resources"
  type        = string
}

// https://docs.oracle.com/en-us/iaas/Content/GSG/Tasks/contactingsupport_topic-Locating_Oracle_Cloud_Infrastructure_IDs.htm#Finding_the_OCID_of_a_Compartment
variable "compartment_ocid" {
  description = "Compartment ocid where to create all resources"
  type        = string
}

variable "compartment_name" {
  description = "Oracle Cloud compartment name"
  type = string
}

variable "instance_name" {
  description = "Name of the instance."
  type        = string
}

variable "ssh_public_keys" {
  default     = null
  description = "Public SSH keys to be included in the ~/.ssh/authorized_keys file for the default user on the instance. To provide multiple keys, see docs/instance_ssh_keys.adoc."
  type        = string
}

variable "user_data" {
  description = "userdata Bash script to execute at VM startup"
  type = string
  default = "#!/bin/bash echo 'hello world from $(hostname -f)'"
}

variable "assign_public_ip" {
  default     = null
  description = "Whether the VNIC should be assigned a public IP address. Defaults to `null` which assigns a public IP based on whether the subnet is public or private. The Free Tier only includes 2 public IP addresses so you may need to set this to `false`"
  type        = bool
}

variable "num_instances" {
  description = "Number of VM instances to create"
  type = number
  default = 1
}

variable "availability_domain" {
  default     = 3
  description = "Availability Domain of the instance"
  type        = number
}

variable "instance_shape" {
  default     = "VM.Standard.A1.Flex"
  description = "The shape of an instance."
  type        = string
}

variable "instance_ocpus" {
  default     = 4
  description = "Number of OCPUs"
  type        = number

  validation {
    condition     = var.instance_ocpus >= 1
    error_message = "The value of ocpus must be greater than or equal to 1."
  }

  validation {
    condition     = var.instance_ocpus <= 4
    error_message = "The value of ocpus must be less than or equal to 4 to remain in the free tier."
  }
}

variable "instance_memory_in_gbs" {
  default     = 24
  description = "Amount of Memory (GB)"
  type        = number
  
  validation {
    condition     = var.instance_memory_in_gbs >= 1
    error_message = "The value of memory_in_gbs must be greater than or equal to 1."
  }

  validation {
    condition     = var.instance_memory_in_gbs <= 24
    error_message = "The value of memory_in_gbs must be less than or equal to 24 to remain in the free tier."
  }
}

variable "instance_source_type" {
  default     = "image"
  description = "The source type for the instance."
  type        = string
}

variable "boot_volume_size_in_gbs" {
  default     = 200
  description = "Boot volume size in GBs"
  type        = number

  validation {
    condition     = var.boot_volume_size_in_gbs == null ? true : var.boot_volume_size_in_gbs >= 50
    error_message = "The value of boot_volume_size_in_gbs must be greater than or equal to 50."
  }

  validation {
    condition     = var.boot_volume_size_in_gbs == null ? true : var.boot_volume_size_in_gbs <= 200
    error_message = "The value of boot_volume_size_in_gbs must be less than or equal to 200 to remain in the free tier."
  }
}

