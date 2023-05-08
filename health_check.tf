resource "google_compute_health_check" "health_check" {
  for_each = (var.healthcheck_config != null && var.region == null) ? var.healthcheck_config : {}
  name                = "hc-${var.name}"
  project             = var.project_id
  description         = each.value.description
  check_interval_sec  = each.value.check_interval_sec
  healthy_threshold   = each.value.healthy_threshold
  unhealthy_threshold = each.value.unhealthy_threshold
  timeout_sec         = each.value.timeout_sec
  dynamic "http_health_check" {
    for_each = each.value.http != null ? [""] : []
    content {
      host               = each.value.http.host
      port               = each.value.http.port
      port_name          = each.value.http.port_name
      proxy_header       = each.value.http.proxy_header
      request_path       = each.value.http.request_path
      response           = each.value.http.response
      port_specification = each.value.http.port_specification
    }
  }
  dynamic "https_health_check" {
    for_each = each.value.https != null ? [""] : []
    content {
      host               = each.value.https.host
      port               = each.value.https.port
      port_name          = each.value.https.port_name
      proxy_header       = each.value.https.proxy_header
      request_path       = each.value.https.request_path
      response           = each.value.https.response
      port_specification = each.value.https.port_specification
    }
  }
  dynamic "http2_health_check" {
    for_each = each.value.http2 != null ? [""] : []
    content {
      host               = each.value.http2.host
      port               = each.value.http2.port
      port_name          = each.value.http2.port_name
      proxy_header       = each.value.http2.proxy_header
      request_path       = each.value.http2.request_path
      response           = each.value.http2.response
      port_specification = each.value.http2.port_specification
    }
  }
  dynamic "log_config" {
    for_each = each.value.enable_log != null ? [""] : []
    content {
      enable = each.value.enable_log
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}

##############################################################################################################################################

resource "google_compute_region_health_check" "health_check" {
  for_each = (!(var.healthcheck_config != null) || var.region == null)? {} : var.healthcheck_config
  name                = "hc-${var.name}"
  project             = var.project_id
  region = var.region
  description         = each.value.description
  check_interval_sec  = each.value.check_interval_sec
  healthy_threshold   = each.value.healthy_threshold
  unhealthy_threshold = each.value.unhealthy_threshold
  timeout_sec         = each.value.timeout_sec
  dynamic "http_health_check" {
    for_each = each.value.http != null ? [""] : []
    content {
      host               = each.value.http.host
      port               = each.value.http.port
      port_name          = each.value.http.port_name
      proxy_header       = each.value.http.proxy_header
      request_path       = each.value.http.request_path
      response           = each.value.http.response
      port_specification = each.value.http.port_specification
    }
  }
  dynamic "https_health_check" {
    for_each = each.value.https != null ? [""] : []
    content {
      host               = each.value.https.host
      port               = each.value.https.port
      port_name          = each.value.https.port_name
      proxy_header       = each.value.https.proxy_header
      request_path       = each.value.https.request_path
      response           = each.value.https.response
      port_specification = each.value.https.port_specification
    }
  }
  dynamic "http2_health_check" {
    for_each = each.value.http2 != null ? [""] : []
    content {
      host               = each.value.http2.host
      port               = each.value.http2.port
      port_name          = each.value.http2.port_name
      proxy_header       = each.value.http2.proxy_header
      request_path       = each.value.http2.request_path
      response           = each.value.http2.response
      port_specification = each.value.http2.port_specification
    }
  }
  dynamic "log_config" {
    for_each = each.value.enable_log != null ? [""] : []
    content {
      enable = each.value.enable_log
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}