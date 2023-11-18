
variable tags    { type = map(string) }
variable ssm     { type = any }
variable tgw     { type = any }
variable rtb     { type = any }
variable core    { type = any }
variable map_code_to_region {type = any }
variable map_region_to_code {type = any }
variable resource_prefixes  { type = map(string) }

variable vpc { type = object({
  create      = bool
  tags        = map(string)
  region      = string
  account     = string
  name        = string
  cidr        = string
  cidr_secondary  = optional(list(string))
  environment = string
  release     = string
  log         = bool
  dual_stack  = bool
  custom_dns = optional(object({
    domain = optional(string)
    forwarders = optional(list(string))
    forward_zones = optional(list(string))
    system_zones = optional(list(string))
  }))
  public = optional(object({
    cidr = optional(list(string))   # list of IP subnets in CIDR notation
    az = optional(list(string))     # list of availability zones ex. [a,b,c]
    role = optional(list(string))   # Custom role name for naming (defaults to "public")
    dia = optional(bool)            # direct internet access: true=IGW False=TGW
    rfc1918_routes = optional(bool) # install RFC1918 routes via TGW, if any
    vpce_s3 = optional(bool)        # deploy S3 gateway endpoint
    vpce_dynamodb = optional(bool)  # deploy DynamoDB gateway endpoint
    vm_debug = optional(bool)       # deploy network debugging virtual machine
  }))
  private = optional(object({
    cidr = optional(list(string))   # list of IP subnets in CIDR notation
    az = optional(list(string))     # list of availability zones ex. [a,b,c]
    role = optional(list(string))   # Custom role names for naming (defaults to "private")
    dia = optional(bool)            # direct internet access: true=NATGW False=TGW
    vpce_s3 = optional(bool)        # deploy S3 gateway endpoint
    vpce_dynamodb = optional(bool)  # deploy DynamoDB gateway endpoint
    vm_debug = optional(bool)       # deploy network debugging virtual machine
  }))
  transit = optional(object({
    cidr = optional(list(string))      # list of IP subnets in CIDR notation
    az = optional(list(string))        # list of availability zones ex. [a,b,c]
    role = optional(list(string))      # Custom role names for naming (defaults to "transit")
    associate = optional(string)       # TGW route table to associate with
    propagate = optional(list(string)) # TGW route table to propagate to
    vm_debug = optional(bool)          # deploy network debugging virtual machine
  }))
})}
