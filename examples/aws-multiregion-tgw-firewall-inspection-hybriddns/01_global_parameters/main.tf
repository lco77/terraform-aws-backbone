################################################################################
# Master data parameters in Deployment account
# This resource must not depend on Jinja as it is used by jinja.py itself !!
################################################################################

module master {
    source    = "./mod_ssm/"
    variables = local.variables
    path      = var.ssm_path
    tags      = local.aws_tags
}

resource "aws_ssm_parameter" "master" {
  name        = "${var.ssm_path}/${var.repository_name}/master.json"
  description = "Configuration item - Do not delete !"
  type        = "String"
  tier        = "Intelligent-Tiering"
  value       = jsonencode(module.emaster.output)
  tags        = local.aws_tags
}