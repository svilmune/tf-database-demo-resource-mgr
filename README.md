# tf-database-demo-resource-mgr

Creates demo stack with Oracle Cloud Infrastructure (OCI) Resource Manager using Terraform which creates an Oracle database and necessary networking resources.

Running this in OCI Resource Manager creates following resources:


* Compartment
* Virtual Cloud Network (VCN)
* Nat Gateway
* Internet Gateway
* Public & Private subnets in the VCN
* Public & Private routetables - Public RT will have a route to Internet Gateway and Private RT route to NAT Gateway
* Public & Private securitylists - Public SL allows traffic to ports 22 and 3389 only. By default it allows traffic from any source but this can be modified to allow only traffic from CIDR block deemed necessary
* One compute instance with the smallest shape to act as a jump server and a 7.6 linux image - the instance public IP will be displayed in the end. 
* One Standard Edition database with the option LICENSE_INCLUDED 

## Requirements 

1. Valid OCI account to install these components
2. Download these .tf files as a zip and navigate in OCI under *Resource Manager*
3. Press "Create Stack" and upload created zip file as your new stack
4. Navigate inside the stack and from the left side menu "Resources" click *Variables* and *Edit Variables*
5. Add following variables:
* region (the name of region you are operating for example eu-frankfurt-1)
* tenancy_ocid (your tenancy's OCID - from left side menu *Administration -> Tenancy Details*)
* ssh_pulic_key (ssh key to be used - you can find create instructions from [here](https://docs.cloud.oracle.com/iaas/Content/GSG/Tasks/creatingkeys.htm))
6. Navigate inside stack and press *Terraform Actions -> Plan*, this usually runs 2-3 minutes
7. If Plan succeeded without issues run *Terraform Actions -> Apply*, this creates resources and will run around 60-90 minutes

## Additional notes

You can freely change the variables in the variables.tf depending what you need. One could potentially scale down the database shape, open different ports in security list or change database version. Try and test!
