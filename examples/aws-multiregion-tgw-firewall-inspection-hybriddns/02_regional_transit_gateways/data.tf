data "aws_ssm_parameter" "aws_tags"              { name = "${var.ssm_path}/aws_tags"              }
data "aws_ssm_parameter" "map_code_to_region"    { name = "${var.ssm_path}/map_code_to_region"    }
data "aws_ssm_parameter" "map_region_to_code"    { name = "${var.ssm_path}/map_region_to_code"    }
data "aws_ssm_parameter" "map_resource_prefixes" { name = "${var.ssm_path}/map_resource_prefixes" }