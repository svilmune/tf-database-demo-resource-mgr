/*

To configure Terraform please visit:

https://www.terraform.io/docs/providers/oci/index.html and set the required variables for your tenant in the machine you are running Terraform on

This is main Terraform code base to create basic environment in Oracle Cloud Infrastructure.

This will create the following resources:

Compartment
Virtual Cloud Network (VCN)
Nat Gateway
Internet Gateway
Public & Private subnets in the VCN
Public & Private routetables - Public RT will have a route to Internet Gateway and Private RT route to NAT Gateway
Public & Private securitylists - Public SL allows traffic to ports 22 and 3389 only. By default it allows traffic from any source but this 
can be modified to allow only traffic from company's IP address to further enhance security

One compute instance with the smallest shape to act as a jump server - the instance public IP will be displayed in the end. 
Single node Standard Edition Database with 2.1 shape, 18.0.0.0 version

Use ssh private key with username "opc" to login into the server. Steps to create SSH key:

https://docs.oracle.com/en/cloud/iaas/compute-iaas-cloud/stcsg/generating-ssh-key-pair.html

Assign the public key on to variable ssh_public_key.


To remove resources:

terraform destroy

Author: Simo Vilmunen 18/12/2018 v0.1
        Simo Vilmunen 06/03/2018 v0.2 Added Resource Manager specific changes - mainly removed provider related variables

*/


provider "oci" {
  tenancy_ocid     = "${var.tenancy_ocid}"
  region           = "${var.region}"
}

// Get available Availability Domains
data "oci_identity_availability_domains" "ADs" {
  compartment_id = "${var.tenancy_ocid}"
}

// Get latest Linux shape but exclude GPU images using
// https://gist.github.com/scross01/bcd21c12b15787f3ae9d51d0d9b2df06#file-oraclelinux-7_5-latest-tf

data "oci_core_images" "oraclelinux" {
  compartment_id = "${oci_identity_compartment.CreateCompartment.id}"

  operating_system         = "${var.operating_system}"
  operating_system_version = "${var.operating_system_version}"

  # exclude GPU specific images
  filter {
    name   = "display_name"
    values = ["^([a-zA-z]+)-([a-zA-z]+)-([\\.0-9]+)-([\\.0-9-]+)$"]
    regex  = true
  }
}

//This part creates a compartment where the resources will be placed on. 

resource "oci_identity_compartment" "CreateCompartment" {
  #Required variables
  compartment_id = "${var.tenancy_ocid}"
  description    = "${var.compartment_description}"
  name           = "${var.compartment_name}"
}

//Create a VCN where subnets will be placed. CIDR block can be defined as required

resource "oci_core_virtual_network" "CreateVCN" {
  cidr_block     = "${var.vcn_cidr_block}"
  dns_label      = "${var.dns_label}"
  compartment_id = "${oci_identity_compartment.CreateCompartment.id}"
  display_name   = "${var.display_name}"
}

//Create NAT GW so private subnet will have access to Internet

resource "oci_core_nat_gateway" "CreateNatGateway" {
  compartment_id = "${oci_identity_compartment.CreateCompartment.id}"
  vcn_id         = "${oci_core_virtual_network.CreateVCN.id}"
  block_traffic  = "${var.nat_gateway_block_traffic}"
  display_name   = "${var.nat_gateway_display_name}"
}

//Create Internet Gateway for Public subnet

resource "oci_core_internet_gateway" "CreateIGW" {
  compartment_id = "${oci_identity_compartment.CreateCompartment.id}"
  enabled        = "${var.internet_gateway_enabled}"
  vcn_id         = "${oci_core_virtual_network.CreateVCN.id}"
  display_name   = "${var.internet_gateway_display_name}"
}

//Create two route tables - one public which has route to internet gateway and another one for private with a route to NAT GW

resource "oci_core_route_table" "CreatePublicRouteTable" {
  compartment_id = "${oci_identity_compartment.CreateCompartment.id}"

  route_rules = [{
    destination       = "${var.igw_route_cidr_block}"
    network_entity_id = "${oci_core_internet_gateway.CreateIGW.id}"
  }]

  vcn_id       = "${oci_core_virtual_network.CreateVCN.id}"
  display_name = "${var.public_route_table_display_name}"
}

resource "oci_core_route_table" "CreatePrivateRouteTable" {
  compartment_id = "${oci_identity_compartment.CreateCompartment.id}"

  route_rules = [{
    destination       = "${var.natgw_route_cidr_block}"
    network_entity_id = "${oci_core_nat_gateway.CreateNatGateway.id}"
  }]

  vcn_id       = "${oci_core_virtual_network.CreateVCN.id}"
  display_name = "${var.private_route_table_display_name}"
}

/*

Create two security lists - for both subnets we will allow traffic outside without restrictions
Public subnet will allow traffic for port 22 
Private subnet will only allow traffic from Public subnet to ports 22 and 1521

*/

resource "oci_core_security_list" "CreatePublicSecurityList" {
  compartment_id = "${oci_identity_compartment.CreateCompartment.id}"
  vcn_id         = "${oci_core_virtual_network.CreateVCN.id}"
  display_name   = "${var.public_sl_display_name}"

  // Allow outbound tcp traffic on all ports
  egress_security_rules {
    destination = "${var.egress_destination}"
    protocol    = "${var.tcp_protocol}"
  }

  // allow inbound ssh traffic from a specific port
  ingress_security_rules = [{
    protocol  = "${var.tcp_protocol}"     // tcp = 6
    source    = "${var.public_ssh_sl_source}" // Can be restricted for specific IP address
    stateless = "${var.rule_stateless}"

    tcp_options {
      // These values correspond to the destination port range.
      "min" = "${var.public_sl_ssh_tcp_port}"
      "max" = "${var.public_sl_ssh_tcp_port}"
    }
  },
    {
      protocol  = "${var.tcp_protocol}"   // tcp = 6
      source    = "${var.vcn_cidr_block}" // open all ports for VCN CIDR and do not block subnet traffic 
      stateless = "${var.rule_stateless}"
    },
  ]
}

resource "oci_core_security_list" "CreatePrivateSecurityList" {
  compartment_id = "${oci_identity_compartment.CreateCompartment.id}"
  vcn_id         = "${oci_core_virtual_network.CreateVCN.id}"
  display_name   = "${var.private_sl_display_name}"

  // Allow outbound tcp traffic on all ports
  egress_security_rules {
    destination = "${var.egress_destination}"
    protocol    = "${var.tcp_protocol}"
  }

  // allow inbound traffic from VCN
  ingress_security_rules = [
    {
      protocol  = "${var.tcp_protocol}"   // tcp = 6
      source    = "${var.vcn_cidr_block}" // VCN CIDR as allowed source and do not block subnet traffic 
      stateless = "${var.rule_stateless}"

      tcp_options {
        // These values correspond to the destination port range.
        "min" = "${var.private_sl_ssh_tcp_port}"
        "max" = "${var.private_sl_ssh_tcp_port}"
      }
    },
    {
      protocol  = "${var.tcp_protocol}"   // tcp = 6
      source    = "${var.vcn_cidr_block}" // open all ports for VCN CIDR and do not block subnet traffic 
      stateless = "${var.rule_stateless}"

      tcp_options {
        // These values correspond to the destination port range.
        "min" = "${var.private_sl_db_tcp_port}"
        "max" = "${var.private_sl_db_tcp_port}"
      }
    },
  ]
}

//Create two subnets - one public where we will place a jump server and a another one where customer specific private resources are created

resource "oci_core_subnet" "CreatePublicSubnet" {
  availability_domain        = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[0],"name")}"
  cidr_block                 = "${cidrsubnet(var.vcn_cidr_block, 8, 0)}"
  display_name               = "${var.public_subnet_display_name}"
  dns_label                  = "${var.public_subnet_dns_label}"
  compartment_id             = "${oci_identity_compartment.CreateCompartment.id}"
  vcn_id                     = "${oci_core_virtual_network.CreateVCN.id}"
  security_list_ids          = ["${oci_core_security_list.CreatePublicSecurityList.id}"]
  route_table_id             = "${oci_core_route_table.CreatePublicRouteTable.id}"
  dhcp_options_id            = "${oci_core_virtual_network.CreateVCN.default_dhcp_options_id}"
  prohibit_public_ip_on_vnic = "${var.public_prohibit_public_ip_on_vnic}"
}

resource "oci_core_subnet" "CreatePrivateSubnet" {
  availability_domain        = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[0],"name")}"
  cidr_block                 = "${cidrsubnet(var.vcn_cidr_block, 8, 1)}"
  display_name               = "${var.private_subnet_display_name}"
  dns_label                  = "${var.private_subnet_dns_label}"
  compartment_id             = "${oci_identity_compartment.CreateCompartment.id}"
  vcn_id                     = "${oci_core_virtual_network.CreateVCN.id}"
  security_list_ids          = ["${oci_core_security_list.CreatePrivateSecurityList.id}"]
  route_table_id             = "${oci_core_route_table.CreatePrivateRouteTable.id}"
  dhcp_options_id            = "${oci_core_virtual_network.CreateVCN.default_dhcp_options_id}"
  prohibit_public_ip_on_vnic = "${var.private_prohibit_public_ip_on_vnic}"
}

// CREATE LINUX INSTANCE IN THE PUBLIC SUBNET

resource "oci_core_instance" "CreateInstance" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[0],"name")}"
  compartment_id      = "${oci_identity_compartment.CreateCompartment.id}"
  shape               = "${var.instance_shape_name}"

  source_details {
    source_id   = "${lookup(data.oci_core_images.oraclelinux.images[0],"id")}"
    source_type = "${var.source_type}"
  }

  create_vnic_details {
    subnet_id        = "${oci_core_subnet.CreatePublicSubnet.id}"
    assign_public_ip = "${var.assign_public_ip}"
    hostname_label = "${var.instance_create_vnic_details_hostname_label}"
  }

  display_name = "${var.instance_display_name}"

  metadata {
    ssh_authorized_keys = "${var.ssh_public_key}"

    #		user_data = "${base64encode(file(var.bootstrapfile))}" // If you want to add bootstrap scripts edit this file
  }

  subnet_id = "${oci_core_subnet.CreatePublicSubnet.id}"
}

// Create DB System in the private subnet
// DB system will by default use the same SSH key provided for the public instance - change if needed

resource "oci_database_db_system" "CreateDBSystem" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[0],"name")}"
  compartment_id = "${oci_identity_compartment.CreateCompartment.id}"
  database_edition = "${var.db_system_database_edition}"
  db_home {
    database {
      admin_password = "${var.db_system_db_home_database_admin_password}"
      character_set = "${var.db_system_db_home_database_character_set}"
      ncharacter_set = "${var.db_system_db_home_database_ncharacter_set}"
      pdb_name = "${var.db_system_db_home_database_pdb_name}"
      db_name = "${var.db_system_db_home_database_db_name}"
    }
    db_version = "${var.db_system_db_home_db_version}"
    display_name = "${var.db_system_db_home_display_name}"
  }
  hostname = "${var.db_system_hostname}"
  shape = "${var.db_system_shape}"
  ssh_public_keys = ["${var.ssh_public_key}"] // Needs to be passed as a list
  subnet_id = "${oci_core_subnet.CreatePrivateSubnet.id}"
  
  // Optional parameters start from here
  // cpu_core_count = "${var.db_system_cpu_core_count}" // Ignored when VM shape is used
 // data_storage_percentage = "${var.db_system_data_storage_percentage}" // Ignored when VM shape is used
  license_model = "${var.db_system_license_model}"
  node_count = "${var.db_system_node_count}"
  data_storage_size_in_gb = "${var.db_system_data_storage_size_in_gbs}"
  
}