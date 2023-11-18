# terraform-modules-aws-multiregion-network
Terraform modules to create an enterprise backbone network on AWS using TGW, Cisco SDWAN, Infoblox / Route53 hybrid DNS and centralized Palo Alto firewall inspection.


# Features

## Global parameters

* Global definitions such as participating account IDs, default tags, public SSH keys or prefix-lists are centrally defined, deployed wherever needed, and consumed by all pipelines

* This avoids duplication of configuration statements and helps keeping the environment globally consistent

## Zero Terraform code to operate

* Once deployed, managing routing, DNS or adding/removing VPCs is done manipulatings JSON-based configuration files only

* From there you can integrate with ITSM processes by automating the provisioning of JSON files and launching pipelines as needed


## Pipeline chaining

* Reduce configuration efforts by passing outputs from one pipeline to another

* Reduce the blast radius in case of issues and keep Terraform state files to a manageable size


## Naming convention enforcement

* Consistently name all resources by centrally mapping each terraform resource type with a name prefix


## Tags inheritance

* Consistently tag resources by centrally defining default tags and allowing overrides per VPC


## Custom mesh TGW-based global network

* Using JSON-based configuration, you can define any kind of routing topology: full mesh, hub and spoke or hierarchical

* Addition/Deletion of TGW route tables and route entries is also fully controlled through JSON configuration


## Centralized Palo Alto firewall inspection into selected regions

* Optionally add Centralized firewall inspection into each region. Internet egress goes through firewall and does not requires NAT gateways or additional EIPs

* Horizontal scaling is supported by adding more firewalls and selectively enabling/disabling per firewall GWLB load balancing through JSON config flags

* TODO: automate the provisioning of per-VPC ingress/egress firewall rules using JSON inputs


## Cisco SDWAN connectivity into selected regions

* Easily deploy SDWAN routers and onboard them into vManage. TGW Connect peerings are used to exchange routes using BGP.


## Hybrid DNS with Infoblox/Route53 integration into selected regions

* Easily manage DNS forwarding between on-prem and native environments using JSON-based configurations only.

* Route53 resolver inbound/outbound endpoints and associated rules are deployed next to DNS appliances into a dedicated DNS VPC.

* Route53 resolver rules are RAM shared with selected accounts inside or outside the organization.

* Route53 private hosted zones are optionaly created and shared the same way.


## Workload VPCs using organization accounts or external accounts

* Easily integrate any kind of accounts into the network. Resource sharing and Terraform providers configurations are fully automated using Jinja2 templates.

* Per VPC, you can also decide to use shared Route53 resolver rules or custom rules. All using JSON-based config only

* TGW attachment and route table association/propagation is also controlled through JSON input

* Optional deployment of S3 and DynamoDB gateway endpoints



# Pre-requisites

The following assumptions are made:

* A deployment account is used to run all pipelines (see https://github.com/lco77/terraform-aws-cicd to create such pipelines)

* A network account is used to deploy the shared infrastructure (TGW, Firewall, SDWAN and DNS stuff)

* Other accounts (from your organization or external accounts) are used to deploy workload VPCs



# Dependencies

## mod_aws_ssm

The "mod_aws_ssm" module is a pre-requisite to all other modules. It deploys global parameters into SSM, well known prefix-lists and your public SSH keys.

## mod_aws_tgw, mod_aws_tgw_accept, mod_aws_tgw_attach, mod_aws_tgw_routing

These modules will set up the global TGW-based network. Other modules such as mod_aws_vpc_sdwan or mod_aws_vpc_inspection depend on it, since they need to attach to TGWs

## mod_aws_vpc_workloads

This module depends on mod_aws_route53* modules to configure DNS into the workload VPCs

# Operation workflows

 Once you have passed the initial deployment. Operating the network can be done without adding new Terraform resources.
 However you must pay attention to some dependencies.

 ## onboarding a new AWS account

 * step 1: add the account into the map_account_to_region JSON parameter using the global parameters pipeline

 * step 2: run transit and hybrid-dns pipelines to update resource sharing associations

 ## deploying a new workload VPC

 * step 1: make sure the account is defined into the map_account_to_region JSON parameter

 * step 2: make sure the target region is enabled into the map_account_to_region JSON parameter

 * optional: run transit and hybrid-dns pipelines to update resource sharing associations (only needed if you updated map_account_to_region in step 1 or 2)

 * step 3: add the JSON config file for the new VPC into the vpc-workloads pipeline and run it