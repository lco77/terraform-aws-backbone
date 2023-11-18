locals {
    variables = jsondecode(file(var.input_file))
    aws_tags  = merge(local.variables.aws_tags,{Reference = var.repository_uri})
}