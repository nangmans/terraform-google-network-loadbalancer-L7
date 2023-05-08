 locals {
    global_http_target_proxy = {for k,v in google_compute_target_http_proxy.proxy : k => v}
    global_https_target_proxy = {for k,v in google_compute_target_https_proxy.proxy : k => v}
    region_http_target_proxy = {for k,v in google_compute_region_target_http_proxy.proxy : k => v}
    region_https_target_proxy = {for k,v in google_compute_region_target_https_proxy.proxy : k => v}
    proxy_ssl_cert = concat(
        coalesce(var.ssl_certificates.certificate_ids,[]),
        [for k,v in google_compute_ssl_certificate.cert: v.id],
        [for k,v in google_compute_managed_ssl_certificate.cert : v.id]
    )
    global_url_map = lookup({for k,v in google_compute_url_map.url_map : k => v}, keys(var.routing_rules)[0], null)
    region_url_map = lookup({for k,v in google_compute_region_url_map.url_map : k => v}, keys(var.routing_rules)[0], null)
    global_external_backend_service = lookup({for k,v in google_compute_backend_service.global_external_backend : k => v}, keys(var.backend_services)[0], null)
    region_external_backend_service = lookup({for k,v in google_compute_region_backend_service.regional_external_backend : k => v}, keys(var.backend_services)[0], null)
    region_internal_backend_service = lookup({for k,v in google_compute_region_backend_service.regional_internal_backend : k => v}, keys(var.backend_services)[0], null)

    module_name    = "terraform-google-network-loadbalancer-L7"
    module_version = "v0.0.1"
 }