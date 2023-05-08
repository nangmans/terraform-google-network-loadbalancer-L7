resource "google_compute_global_forwarding_rule" "global_external_rule" {
    for_each = (var.frontend_configs != null && var.is_external && var.region == null) ? var.frontend_configs : {}
    name = "fr-${var.name}-${each.key}"
    project = var.project_id
    target = each.value.protocol == "HTTP" ? lookup(local.global_http_target_proxy, each.key, null).id : each.value.protocol == "HTTPS" ? lookup(local.global_https_target_proxy, each.key, null).id : null
    description = each.value.description
    ip_address = each.value.ip_address
    ip_protocol = "TCP"
    ip_version = each.value.ip_version
    load_balancing_scheme = "EXTERNAL_MANAGED" 
    port_range = each.value.port
}

##############################################################################################################################################

resource "google_compute_forwarding_rule" "regional_internal_rule" {
    for_each = (!(var.frontend_configs != null) || var.is_external || var.region == null) ? {} : var.frontend_configs 
    name = "fr-${var.name}-${each.key}"
    region = var.region
    subnetwork = each.value.subnet
    network = each.value.network
    project = var.project_id
    allow_global_access = each.value.allow_global_access
    service_label = each.value.service_label
    target = each.value.protocol == "HTTP" ? lookup(local.region_http_target_proxy, each.key, null).id : each.value.protocol == "HTTPS" ? lookup(local.region_https_target_proxy, each.key, null).id : null
    description = each.value.description
    ip_address = each.value.ip_address
    ip_protocol = "TCP"
    load_balancing_scheme = "INTERNAL_MANAGED" 
    port_range = each.value.port
    dynamic "service_directory_registrations" {
        for_each = each.value.service_directory_registration != null ? [""] : []
        content {
            namespace = each.value.service_directory_registration.namespace
            service = each.value.service_directory_registration.service
        }
    }
}

##############################################################################################################################################

resource "google_compute_forwarding_rule" "regional_external_rule" {
    for_each = (!(var.frontend_configs != null) || !var.is_external || var.region == null) ? {} : var.frontend_configs 
    name = "fr-${var.name}-${each.key}"
    region = var.region
    network = var.network
    project = var.project_id
    allow_global_access = each.value.allow_global_access
    service_label = each.value.service_label
    target = each.value.protocol == "HTTP" ? lookup(local.region_http_target_proxy, each.key, null).id : each.value.protocol == "HTTPS" ? lookup(local.region_https_target_proxy, each.key, null).id : null
    description = each.value.description
    ip_address = each.value.ip_address
    network_tier = "STANDARD"
    ip_protocol = "TCP"
    load_balancing_scheme = "EXTERNAL_MANAGED" 
    port_range = each.value.port
    dynamic "service_directory_registrations" {
        for_each = each.value.service_directory_registration != null ? [""] : []
        content {
            namespace = each.value.service_directory_registration.namespace
            service = each.value.service_directory_registration.service
        }
    }
}