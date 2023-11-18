variable region             { type = string      }
variable data               { type = any         }
variable map_code_to_region { type = map(string) }
variable map_region_to_code { type = map(string) }
variable tags               { type = map(string) }
variable resource_prefixes  { type = map(string) }