import os
import json
import boto3
from jinja2 import Environment, FileSystemLoader

################################################################################
# TF generator
# Caution: do not remove accounts or regions from SSM parameters until all
# relevant resources are destroyed !
# Doing so will result into orphaned objects in Terraform state.
################################################################################

map_code_to_region    = "/network/map_code_to_region"
map_account_to_region = "/network/map_account_to_region"

################################################################################
# load SSM parameter
################################################################################

def get_ssm(name:str)->dict:
    try:
        ssm = boto3.client('ssm')
        param = ssm.get_parameter(Name=name)
    except:
        print(f"Error getting {name}\n")
        return False
    return json.loads(param["Parameter"]["Value"])

dict_map_code_to_region    = get_ssm(map_code_to_region)
dict_map_account_to_region = get_ssm(map_account_to_region)

if dict_map_code_to_region and dict_map_account_to_region:
    data = {
        "regions":  dict_map_code_to_region,
        "accounts": dict_map_account_to_region
        }
else:
    exit(1)

################################################################################
# jinja-ram-associations.tf
################################################################################

template_file = "jinja-ram-associations.jinja2"
output_file   = "jinja-ram-associations.tf"
environment = Environment(loader=FileSystemLoader("templates/"))
template    = environment.get_template(template_file)
with open(output_file, mode="w", encoding="utf-8") as out:
    out.write(template.render(data))

################################################################################
# jinja-ram-accepters.tf
################################################################################

template_file = "jinja-ram-accepters.jinja2"
output_file   = "jinja-ram-accepters.tf"
environment = Environment(loader=FileSystemLoader("templates/"))
template    = environment.get_template(template_file)
with open(output_file, mode="w", encoding="utf-8") as out:
    out.write(template.render(data))

################################################################################
# jinja-providers.tf
################################################################################

template_file = "jinja-providers.jinja2"
output_file   = "jinja-providers.tf"
environment = Environment(loader=FileSystemLoader("templates/"))
template    = environment.get_template(template_file)
with open(output_file, mode="w", encoding="utf-8") as out:
    out.write(template.render(data))

################################################################################
# terraform init
################################################################################

os.system('terraform init')