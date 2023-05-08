resource "null_resource" "validate_module_name" {
  count = local.module_name == var.validate_labels["terraform-module-name"] ? 0 : "Please check that you are using the Terraform module"
}

resource "null_resource" "validate_module_version" {
  count = local.module_version == var.validate_labels["terraform-module-version"] ? 0 : "Please check that you are using the Terraform module"
}