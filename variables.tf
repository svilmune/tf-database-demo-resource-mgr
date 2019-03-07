/*

These are variables to create basic environment in Oracle Cloud Infrastructure.

Depending on requirement variables can be modified. Following environment variables must be set in the resource manager variables section:

* region
* tenancy_ocid
* ssh_public_key

For more detailed instructions review main.tf

Author: Simo Vilmunen 16/12/2018 

*/


// ORACLE LINUX VERSION AND OS NAME

variable "operating_system" {
  default = "Oracle Linux"
} // Name for the OS

variable "operating_system_version" {
  default = "7.6"
} // OS Version

// COMPARTMENT VARIABLES
variable "compartment_name" {
  default = "MyCompartment"
} // Name for the compartment

variable "compartment_description" {
  default = "This compartment holds all the DEMO resources"
} // Description for the compartment

// VCN VARIABLES
variable "vcn_cidr_block" {
  default = "172.16.0.0/16"
} // Define the CIDR block for your OCI cloud

variable "display_name" {
  default = "My VCN"
} // VCN Name

variable "dns_label" {
  default = "oci"
} // DNS Label for VCN

// NAT GW VARIABLES
variable "nat_gateway_display_name" {
  default = "NatGateway"
} // Name for the NAT GW

variable "nat_gateway_block_traffic" {
  default = "false"
} // Is NAT GW active or not

// INTERNET GW VARIABLES

variable "internet_gateway_display_name" {
  default = "InternetGateway"
} // Name for the IGW

variable "internet_gateway_enabled" {
  default = "true"
} // Is IGW enabled or not

// PUBLIC AND PRIVATE ROUTETABLE VARIABLES

variable "public_route_table_display_name" {
  default = "PublicRoute"
} // Name for the public routetable

variable "private_route_table_display_name" {
  default = "PrivateRoute"
} // Name for the private routetable

variable "igw_route_cidr_block" {
  default = "0.0.0.0/0"
}

variable "natgw_route_cidr_block" {
  default = "0.0.0.0/0"
}

// PUBLIC AND PRIVATE SECURITYLIST VARIABLES

variable "public_sl_display_name" {
  default = "PublicSL"
} // Name for the public securitylist

variable "private_sl_display_name" {
  default = "PrivateSL"
} // Name for the private securitylist

variable "egress_destination" {
  default = "0.0.0.0/0"
} // Outside traffic is allowed

variable "tcp_protocol" {
  default = "6"
} // 6 for TCP traffic

variable "public_ssh_sl_source" {
  default = "0.0.0.0/0"
}

variable "rule_stateless" {
  default = "false"
} // All rules are stateful by default so no need to define rules both ways

variable "public_sl_ssh_tcp_port" {
  default = "22"
} // Open port 22 for SSH access

variable "private_sl_ssh_tcp_port" {
  default = "22"
} // Open port 22 for SSH access

variable "private_sl_db_tcp_port" {
  default = "1521"
} // Open port 1521 for DB listener

// PUBLIC AND PRIVATE SUBNET VARIABLES
variable "public_subnet_display_name" {
  default = "PublicSubnet"
} // Name for public subnet

variable "private_subnet_display_name" {
  default = "PrivateSubnet"
} // Name for private subnet

variable "public_subnet_dns_label" {
  default = "pub"
} // DNS Label for public subnet

variable "private_subnet_dns_label" {
  default = "pri"
} // DNS label for private subnet

variable "public_prohibit_public_ip_on_vnic" {
  default = "false"
} // Can instances in public subnet get public IP

variable "private_prohibit_public_ip_on_vnic" {
  default = "true"
}

// Can instances in private subnet get public IP

// INSTANCE VARIABLES

// Image for the compute instance - change this to Windows image if needed
variable "instance_shape_name" {
  default = "VM.Standard2.1"
}

// Shape what to be used. Smallest shape selected by default
variable "source_type" {
  default = "image"
} // What type the image source is


// Create your own SSH key for the image and paste the public key here
// See https://docs.oracle.com/en/cloud/iaas/compute-iaas-cloud/stcsg/generating-ssh-key-pair.html for more details
// Windows images do not use SSH key
variable "assign_public_ip" {
  default = "true"
}

// Since this is server in public subnet it will have a public IP
variable "instance_display_name" {
  default = "MyPublicServer"
} // Name for the instance

variable "instance_create_vnic_details_hostname_label" {
  default = "public-1"
}

// Database system variables

/*variable "db_system_cpu_core_count" {
  default = "1"
  }
  */
variable "db_system_database_edition" {
  default = "STANDARD_EDITION"
  } // Using Standard Edition here but can be changed to ENTERPRISE_EDITION if needed
variable "db_system_db_home_database_admin_password" {
  default = "First1_Database2_"
  } // 9-30 characters, two uppercase, two numbers, two special
variable "db_system_db_home_database_db_name" {
  default = "TEST"
  }
variable "db_system_db_home_database_character_set" {
  default = "AL32UTF8"
  }

variable "db_system_db_home_database_ncharacter_set" {
  default = "AL16UTF16"
  }
variable "db_system_db_home_database_pdb_name" {
  default = "TESTPDB"
  }
variable "db_system_db_home_db_version" {
  default = "18.0.0.0"
  }
variable "db_system_db_home_display_name" {
  default = "HOME1"
  } #Optional
variable "db_system_hostname" {
  default = "testhost"
  }
variable "db_system_shape" {
  default = "VM.Standard2.1"
  } // Adjust when needed with 2.2, 2.4 etc..

// Optional DB system variables
variable "db_system_data_storage_percentage" {
  default = "80"
  }

/*
variable "db_system_display_name" {
  default = "TEST DB"
  }
*/ // Not applicable for virtual DB systems
variable "db_system_license_model" {
  default = "BRING_YOUR_OWN_LICENSE"
  }
variable "db_system_node_count" {
  default = "1"
  }
variable "db_system_data_storage_size_in_gbs" {
  default = "256"
  } 
