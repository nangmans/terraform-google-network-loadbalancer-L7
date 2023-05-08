resource "google_compute_target_http_proxy" "proxy" {
    for_each = var.region == null ? {
        for k,v in var.frontend_configs :  k => v if v.protocol == "HTTP" 
        } : {}
    name = "tp-${var.name}-${each.key}"
    url_map = local.global_url_map.id
    description = "This target proxy is created by terraform"
    project = var.project_id

}

resource "google_compute_target_https_proxy" "proxy" {
    for_each = var.region == null ? {
        for k,v in var.frontend_configs :  k => v if v.protocol == "HTTPS" 
        } : {}
    name = "tp-${var.name}-${each.value.key}"
    url_map = local.global_url_map.id
    description = "This target proxy is created by terraform"
    quic_override = each.value.quic_negotiation
    ssl_certificates = local.proxy_ssl_cert
    certificate_map = each.value.certificate_map
    ssl_policy = each.value.ssl_policy
    project = var.project_id

}

##############################################################################################################################################

resource "google_compute_region_target_http_proxy" "proxy" {
    for_each = var.region == null ? {} : {
        for k,v in var.frontend_configs :  k => v if v.protocol == "HTTP" 
        }
    name = "tp-${var.name}-${each.key}"
    url_map = local.region_url_map.id
    region = var.region
    description = "This target proxy is created by terraform"
    project = var.project_id
}

resource "google_compute_region_target_https_proxy" "proxy" {
    for_each = var.region == null ? {} : {
        for k,v in var.frontend_configs :  k => v if v.protocol == "HTTPS" 
        } 
    name = "tp-${var.name}-${each.key}"
    url_map = local.region_url_map.id
    region = var.region
    description = "This target proxy is created by terraform"
    ssl_certificates = local.proxy_ssl_cert
    project = var.project_id

}