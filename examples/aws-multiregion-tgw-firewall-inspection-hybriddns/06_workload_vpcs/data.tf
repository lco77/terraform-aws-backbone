data "aws_ssm_parameter" "aws_tags"              { name = "${var.ssm_path}/aws_tags"                 }
data "aws_ssm_parameter" "map_code_to_region"    { name = "${var.ssm_path}/map_code_to_region"       }
data "aws_ssm_parameter" "map_region_to_code"    { name = "${var.ssm_path}/map_region_to_code"       }
data "aws_ssm_parameter" "map_resource_prefixes" { name = "${var.ssm_path}/map_resource_prefixes"    }
data "aws_ssm_parameter" "transit_gateways"      { name = "${var.ssm_path}/transit_gateways.json" }
data "aws_ssm_parameter" "transit_routing"       { name = "${var.ssm_path}/transit_routing.json" }
data "aws_ssm_parameter" "aws_core_euw1"         { name = "${var.ssm_path}/dns/euw1.json"  }
data "aws_ssm_parameter" "aws_core_use1"         { name = "${var.ssm_path}/dns/use1.json"  }

# Load assets
data "local_file" "assets" {
    for_each = {for i,v in local.fileset: v => v}
    filename = "${path.module}/${each.value}"
}