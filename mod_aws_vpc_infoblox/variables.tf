
variable tags { type = map(string) }
variable map_code_to_region {type = map(string) }
variable map_region_to_code {type = map(string) }
variable resource_prefixes  { type = map(string) }

variable vpc      { type = any  }
variable tgw      { type = any  }
variable rtb      { type = any  }

