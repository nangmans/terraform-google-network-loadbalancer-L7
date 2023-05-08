resource "google_compute_backend_service" "global_external_backend" {
  for_each = (var.backend_services != null && var.is_external && var.region == null) ? var.backend_services : {}
  name = "bs-${var.name}-${each.key}"
  project = try(each.value.project_id, var.project_id)
  description = each.value.description
  protocol = each.value.protocol
  timeout_sec = each.value.timeout_sec
  port_name = each.value.named_port == null ? lower(each.value.protocol) : each.value.named_port
  affinity_cookie_ttl_sec = each.value.affinity_cookie_ttl_sec
  connection_draining_timeout_sec = each.value.connection_draining_timeout_sec
  custom_request_headers = each.value.custom_request_headers
  custom_response_headers = each.value.custom_response_headers
  health_checks = each.value.health_check
  load_balancing_scheme = "EXTERNAL_MANAGED" 
  locality_lb_policy = each.value.locality_lb_policy
  security_policy = each.value.security_policy
  session_affinity = each.value.session_affinity
  enable_cdn = try(each.value.cdn_policy.enable_cloud_cdn , null)
  dynamic "backend" {
    for_each = {
      for k,v in each.value.backends :
      k => v
    }
    iterator = backend
    content {
      group = backend.value.group
      description = backend.value.description
      balancing_mode = (each.value.backend_type == "NEG" || backend.value.balancing_mode.rate != null) ? "RATE" : backend.value.balancing_mode.utilization != null ? "UTILIZATION" : null
      max_utilization = try(backend.value.balancing_mode.utilization.max_utilization, null)
      max_connections = try(backend.value.balancing_mode.utilization.max_connections, null)
      max_connections_per_instance = try(backend.value.balancing_mode.utilization.max_connections_per_instance, null)
      max_rate = try(
        (each.value.backend_type == "NEG" || backend.value.balancing_mode.rate != null) 
        ? backend.value.balancing_mode.rate.max_rps_per_group : backend.value.balancing_mode.utilization != null 
        ? backend.value.balancing_mode.utilization.max_rps_per_group : null
      )
      max_rate_per_instance = try(
        (each.value.backend_type == "NEG" || backend.value.balancing_mode.rate != null) 
        ? backend.value.balancing_mode.rate.max_rps_per_instance : backend.value.balancing_mode.utilization != null 
        ? backend.value.balancing_mode.utilization.max_rps_per_instance : null
      )
      capacity_scaler = backend.value.balancing_mode.capacity
    }
  }
  dynamic "circuit_breakers" {
    for_each = each.value.circuit_breakers != null ? [each.value.circuit_breakers] : []
    iterator = config
    content {
      max_connections = config.value.max_connections
      max_requests_per_connection = config.value.max_requests_per_connection
      max_pending_requests = config.value.max_pending_requests
      max_requests = config.value.max_requests
      max_retries = config.value.max_retries
    }
  }
  dynamic "consistent_hash" {
    for_each = each.value.consistent_hash != null ? [each.value.consistent_hash] : []
    iterator = config
    content {
      http_header_name = config.value.http_header_name
      minimum_ring_size = config.value.minimum_ring_size
      dynamic "http_cookie" {
        for_each  = config.value.http_cookie != null ? [config.value.http_cookie] : []
        iterator = cookie
        content {
          name = cookie.value.name
          path = cookie.value.path
          dynamic "ttl" {
            for_each = cookie.value.ttl != null ? [cookie.value.ttl] : []
            content {
              seconds = ttl.value.seconds
              nanos = ttl.value.nanos
            }
          }
        }
      }
    }
  }
  dynamic "cdn_policy" {
    for_each = each.value.cdn_policy != null ? [each.value.cdn_policy] : []
    iterator = config
    content {
      cache_mode = config.value.cache_mode
      client_ttl = config.value.client_ttl_sec
      default_ttl = config.value.default_ttl_sec
      max_ttl = config.value.max_ttl_sec
      serve_while_stale = config.value.serve_while_stale
      signed_url_cache_max_age_sec = config.value.signed_url_cache_max_age_sec
      negative_caching = config.value.enable_negative_caching
      dynamic "negative_caching_policy" {
        for_each = {
          for k,v in config.value.negative_caching_policy : k => v
        }
        iterator = policy
        content {
          code = policy.value.code
          ttl = policy.value.ttl_sec
        }
      }
      dynamic "cache_key_policy" {
        for_each = config.value.cache_key_policy != null ? [config.value.cache_key_policy] : []
        iterator = policy
        content {
          include_host = policy.value.include_host
          include_protocol = policy.value.include_protocol
          include_query_string = policy.value.include_query_string
          include_http_headers = policy.value.include_http_headers
          include_named_cookies = policy.value.include_named_cookies
          query_string_blacklist = policy.value.query_string_blacklist
          query_string_whitelist = policy.value.query_string_whitelist
        }
      }
    }
  }
  dynamic "log_config" {
    for_each = each.value.log_config != null ? [each.value.log_config] : []
    iterator = config
    content {
      enable = config.value.enable
      sample_rate = config.value.sample_rate
    }
  }
  dynamic "outlier_detection" {
    for_each = each.value.outlier_detection != null ? [each.value.outlier_detection] : []
    iterator = config
    content {
      max_ejection_percent = config.value.max_ejection_percent
      success_rate_minimum_hosts = config.value.success_rate_minimum_hosts
      success_rate_stdev_factor = config.value.success_rate_stdev_factor
      success_rate_request_volume = config.value.success_rate_request_volume
      enforcing_consecutive_errors = config.value.enforcing_consecutive_errors
      enforcing_consecutive_gateway_failure = config.value.enforcing_consecutive_gateway_failure
      enforcing_success_rate = config.value.enforcing_success_rate
      consecutive_gateway_failure = config.value.consecutive_gateway_failure
      consecutive_errors = config.value.consecutive_errors
      dynamic "interval" {
        for_each = config.value.interval != null ? [config.value.interval] : []
        content {
          seconds = interval.value.seconds
          nanos = interval.value.nanos
        }
      }
      dynamic "base_ejection_time" {
        for_each = config.value.base_ejection_time != null ? [config.value.base_ejection_time]  : []
        iterator = time
        content {
          seconds = time.value.seconds
          nanos = time.value.nanos
        }
      }
    }
  }
  dynamic "iap" {
    for_each = each.value.iap_config != null ? [each.value.iap_config] : []
    iterator = iap
    content {
      oauth2_client_id = iap.value.oauth2_client_id
      oauth2_client_secret = iap.value.oauth2_client_secret
      oauth2_client_secret_sha256 = iap.value.oauth2_client_secret_sha256
    }
  }

  depends_on = [
    google_compute_health_check.health_check
  ]
}

##############################################################################################################################################

resource "google_compute_region_backend_service" "regional_internal_backend" {
  for_each = (!(var.backend_services != null) || var.is_external || var.region == null) ? {} : var.backend_services
  name = "bs-${var.name}-${each.key}"
  project = try(each.value.project_id, var.project_id)
  region  = var.region
  description = each.value.description
  protocol = each.value.protocol
  timeout_sec = each.value.timeout_sec
  port_name = each.value.named_port == null ? lower(each.value.protocol) : each.value.named_port
  affinity_cookie_ttl_sec = each.value.affinity_cookie_ttl_sec
  connection_draining_timeout_sec = each.value.connection_draining_timeout_sec
  health_checks = ["https://www.googleapis.com/compute/v1/projects/${var.project_id}/regions/${var.region}/healthChecks/${each.value.health_check.0}"]
  load_balancing_scheme = "INTERNAL_MANAGED" 
  locality_lb_policy = each.value.locality_lb_policy
  session_affinity = each.value.session_affinity
  enable_cdn = try(each.value.cdn_policy.enable_cloud_cdn , null)
  dynamic "backend" {
    for_each = {
      for k,v in each.value.backends :
      k => v
    }
    iterator = backend
    content {
      group = backend.value.group
      description = backend.value.description
      balancing_mode = (each.value.backend_type == "NEG" || backend.value.balancing_mode.rate != null) ? "RATE" : backend.value.balancing_mode.utilization != null ? "UTILIZATION" : null
      max_utilization = try(backend.value.balancing_mode.utilization.max_utilization, null)
      max_connections = try(backend.value.balancing_mode.utilization.max_connections, null)
      max_connections_per_instance = try(backend.value.balancing_mode.utilization.max_connections_per_instance, null)
      max_rate = try(
        (each.value.backend_type == "NEG" || backend.value.balancing_mode.rate != null) 
        ? backend.value.balancing_mode.rate.max_rps_per_group : backend.value.balancing_mode.utilization != null 
        ? backend.value.balancing_mode.utilization.max_rps_per_group : null
      )
      max_rate_per_instance = try(
        (each.value.backend_type == "NEG" || backend.value.balancing_mode.rate != null) 
        ? backend.value.balancing_mode.rate.max_rps_per_instance : backend.value.balancing_mode.utilization != null 
        ? backend.value.balancing_mode.utilization.max_rps_per_instance : null
      )
      capacity_scaler = backend.value.balancing_mode.capacity
    }
  }
  dynamic "circuit_breakers" {
    for_each = each.value.circuit_breakers != null ? [each.value.circuit_breakers] : []
    iterator = config
    content {
      max_connections = config.value.max_connections
      max_requests_per_connection = config.value.max_requests_per_connection
      max_pending_requests = config.value.max_pending_requests
      max_requests = config.value.max_requests
      max_retries = config.value.max_retries
    }
  }
  dynamic "consistent_hash" {
    for_each = each.value.consistent_hash != null ? [each.value.consistent_hash] : []
    iterator = config
    content {
      http_header_name = config.value.http_header_name
      minimum_ring_size = config.value.minimum_ring_size
      dynamic "http_cookie" {
        for_each  = config.value.http_cookie != null ? [config.value.http_cookie] : []
        iterator = cookie
        content {
          name = cookie.value.name
          path = cookie.value.path
          dynamic "ttl" {
            for_each = cookie.value.ttl != null ? [cookie.value.ttl] : []
            content {
              seconds = ttl.value.seconds
              nanos = ttl.value.nanos
            }
          }
        }
      }
    }
  }
  dynamic "failover_policy" {
    for_each = each.value.failover_policy != null ? [""] : []
    content {
      disable_connection_drain_on_failover = each.value.failover_policy.disable_connection_drain_on_failover
      drop_traffic_if_unhealthy = each.value.failover_policy.drop_traffic_if_unhealthy
      failover_ratio = each.value.failover_policy.failover_ratio
    }
  }
  dynamic "cdn_policy" {
    for_each = each.value.cdn_policy != null ? [each.value.cdn_policy] : []
    iterator = config
    content {
      cache_mode = config.value.cache_mode
      client_ttl = config.value.client_ttl_sec
      default_ttl = config.value.default_ttl_sec
      max_ttl = config.value.max_ttl_sec
      serve_while_stale = config.value.serve_while_stale
      signed_url_cache_max_age_sec = config.value.signed_url_cache_max_age_sec
      negative_caching = config.value.enable_negative_caching
      dynamic "negative_caching_policy" {
        for_each = {
          for k,v in config.value.negative_caching_policy : k => v
        }
        iterator = policy
        content {
          code = policy.value.code
          #ttl = policy.value.ttl_sec  # Beta attribute
        }
      }
      dynamic "cache_key_policy" {
        for_each = config.value.cache_key_policy != null ? [config.value.cache_key_policy] : []
        iterator = policy
        content {
          include_host = policy.value.include_host
          include_protocol = policy.value.include_protocol
          include_query_string = policy.value.include_query_string
          include_named_cookies = policy.value.include_named_cookies
          query_string_blacklist = policy.value.query_string_blacklist
          query_string_whitelist = policy.value.query_string_whitelist
        }
      }
    }
  }
  dynamic "log_config" {
    for_each = each.value.log_config != null ? [each.value.log_config] : []
    iterator = config
    content {
      enable = config.value.enable
      sample_rate = config.value.sample_rate
    }
  }
  dynamic "outlier_detection" {
    for_each = each.value.outlier_detection != null ? [each.value.outlier_detection] : []
    iterator = config
    content {
      max_ejection_percent = config.value.max_ejection_percent
      success_rate_minimum_hosts = config.value.success_rate_minimum_hosts
      success_rate_stdev_factor = config.value.success_rate_stdev_factor
      success_rate_request_volume = config.value.success_rate_request_volume
      enforcing_consecutive_errors = config.value.enforcing_consecutive_errors
      enforcing_consecutive_gateway_failure = config.value.enforcing_consecutive_gateway_failure
      enforcing_success_rate = config.value.enforcing_success_rate
      consecutive_gateway_failure = config.value.consecutive_gateway_failure
      consecutive_errors = config.value.consecutive_errors
      dynamic "interval" {
        for_each = config.value.interval != null ? [config.value.interval] : []
        content {
          seconds = interval.value.seconds
          nanos = interval.value.nanos
        }
      }
      dynamic "base_ejection_time" {
        for_each = config.value.base_ejection_time != null ? [config.value.base_ejection_time]  : []
        iterator = time
        content {
          seconds = time.value.seconds
          nanos = time.value.nanos
        }
      }
    }
  }
  dynamic "iap" {
    for_each = each.value.iap_config != null ? [each.value.iap_config] : []
    iterator = iap
    content {
      oauth2_client_id = iap.value.oauth2_client_id
      oauth2_client_secret = iap.value.oauth2_client_secret
      oauth2_client_secret_sha256 = iap.value.oauth2_client_secret_sha256
    }
  }

  depends_on = [
    google_compute_region_health_check.health_check
  ]
}

##############################################################################################################################################

resource "google_compute_region_backend_service" "regional_external_backend" {
  for_each = (!(var.backend_services != null) || !var.is_external || var.region == null) ? {} : var.backend_services
  name = "bs-${var.name}-${each.key}"
  project = try(each.value.project_id, var.project_id)
  region  = var.region
  description = each.value.description
  protocol = each.value.protocol
  timeout_sec = each.value.timeout_sec
  port_name = each.value.named_port == null ? lower(each.value.protocol) : each.value.named_port
  affinity_cookie_ttl_sec = each.value.affinity_cookie_ttl_sec
  connection_draining_timeout_sec = each.value.connection_draining_timeout_sec
  health_checks = ["https://www.googleapis.com/compute/v1/projects/${var.project_id}/regions/${var.region}/healthChecks/${each.value.health_check.0}"]
  load_balancing_scheme = "EXTERNAL_MANAGED" 
  locality_lb_policy = each.value.locality_lb_policy
  session_affinity = each.value.session_affinity
  enable_cdn = try(each.value.cdn_policy.enable_cloud_cdn , null)
  dynamic "backend" {
    for_each = {
      for k,v in each.value.backends :
      k => v
    }
    iterator = backend
    content {
      group = backend.value.group
      description = backend.value.description
      balancing_mode = (each.value.backend_type == "NEG" || backend.value.balancing_mode.rate != null) ? "RATE" : backend.value.balancing_mode.utilization != null ? "UTILIZATION" : null
      max_utilization = try(backend.value.balancing_mode.utilization.max_utilization, null)
      max_connections = try(backend.value.balancing_mode.utilization.max_connections, null)
      max_connections_per_instance = try(backend.value.balancing_mode.utilization.max_connections_per_instance, null)
      max_rate = try(
        (each.value.backend_type == "NEG" || backend.value.balancing_mode.rate != null) 
        ? backend.value.balancing_mode.rate.max_rps_per_group : backend.value.balancing_mode.utilization != null 
        ? backend.value.balancing_mode.utilization.max_rps_per_group : null
      )
      max_rate_per_instance = try(
        (each.value.backend_type == "NEG" || backend.value.balancing_mode.rate != null) 
        ? backend.value.balancing_mode.rate.max_rps_per_instance : backend.value.balancing_mode.utilization != null 
        ? backend.value.balancing_mode.utilization.max_rps_per_instance : null
      )
      capacity_scaler = backend.value.balancing_mode.capacity
    }
  }
  dynamic "circuit_breakers" {
    for_each = each.value.circuit_breakers != null ? [each.value.circuit_breakers] : []
    iterator = config
    content {
      max_connections = config.value.max_connections
      max_requests_per_connection = config.value.max_requests_per_connection
      max_pending_requests = config.value.max_pending_requests
      max_requests = config.value.max_requests
      max_retries = config.value.max_retries
    }
  }
  dynamic "consistent_hash" {
    for_each = each.value.consistent_hash != null ? [each.value.consistent_hash] : []
    iterator = config
    content {
      http_header_name = config.value.http_header_name
      minimum_ring_size = config.value.minimum_ring_size
      dynamic "http_cookie" {
        for_each  = config.value.http_cookie != null ? [config.value.http_cookie] : []
        iterator = cookie
        content {
          name = cookie.value.name
          path = cookie.value.path
          dynamic "ttl" {
            for_each = cookie.value.ttl != null ? [cookie.value.ttl] : []
            content {
              seconds = ttl.value.seconds
              nanos = ttl.value.nanos
            }
          }
        }
      }
    }
  }
  dynamic "failover_policy" {
    for_each = each.value.failover_policy != null ? [""] : []
    content {
      disable_connection_drain_on_failover = each.value.failover_policy.disable_connection_drain_on_failover
      drop_traffic_if_unhealthy = each.value.failover_policy.drop_traffic_if_unhealthy
      failover_ratio = each.value.failover_policy.failover_ratio
    }
  }
  dynamic "cdn_policy" {
    for_each = each.value.cdn_policy != null ? [each.value.cdn_policy] : []
    iterator = config
    content {
      cache_mode = config.value.cache_mode
      client_ttl = config.value.client_ttl_sec
      default_ttl = config.value.default_ttl_sec
      max_ttl = config.value.max_ttl_sec
      serve_while_stale = config.value.serve_while_stale
      signed_url_cache_max_age_sec = config.value.signed_url_cache_max_age_sec
      negative_caching = config.value.enable_negative_caching
      dynamic "negative_caching_policy" {
        for_each = {
          for k,v in config.value.negative_caching_policy : k => v
        }
        iterator = policy
        content {
          code = policy.value.code
          #ttl = policy.value.ttl_sec  # Beta attribute
        }
      }
      dynamic "cache_key_policy" {
        for_each = config.value.cache_key_policy != null ? [config.value.cache_key_policy] : []
        iterator = policy
        content {
          include_host = policy.value.include_host
          include_protocol = policy.value.include_protocol
          include_query_string = policy.value.include_query_string
          include_named_cookies = policy.value.include_named_cookies
          query_string_blacklist = policy.value.query_string_blacklist
          query_string_whitelist = policy.value.query_string_whitelist
        }
      }
    }
  }
  dynamic "log_config" {
    for_each = each.value.log_config != null ? [each.value.log_config] : []
    iterator = config
    content {
      enable = config.value.enable
      sample_rate = config.value.sample_rate
    }
  }
  dynamic "outlier_detection" {
    for_each = each.value.outlier_detection != null ? [each.value.outlier_detection] : []
    iterator = config
    content {
      max_ejection_percent = config.value.max_ejection_percent
      success_rate_minimum_hosts = config.value.success_rate_minimum_hosts
      success_rate_stdev_factor = config.value.success_rate_stdev_factor
      success_rate_request_volume = config.value.success_rate_request_volume
      enforcing_consecutive_errors = config.value.enforcing_consecutive_errors
      enforcing_consecutive_gateway_failure = config.value.enforcing_consecutive_gateway_failure
      enforcing_success_rate = config.value.enforcing_success_rate
      consecutive_gateway_failure = config.value.consecutive_gateway_failure
      consecutive_errors = config.value.consecutive_errors
      dynamic "interval" {
        for_each = config.value.interval != null ? [config.value.interval] : []
        content {
          seconds = interval.value.seconds
          nanos = interval.value.nanos
        }
      }
      dynamic "base_ejection_time" {
        for_each = config.value.base_ejection_time != null ? [config.value.base_ejection_time]  : []
        iterator = time
        content {
          seconds = time.value.seconds
          nanos = time.value.nanos
        }
      }
    }
  }
  dynamic "iap" {
    for_each = each.value.iap_config != null ? [each.value.iap_config] : []
    iterator = iap
    content {
      oauth2_client_id = iap.value.oauth2_client_id
      oauth2_client_secret = iap.value.oauth2_client_secret
      oauth2_client_secret_sha256 = iap.value.oauth2_client_secret_sha256
    }
  }

  depends_on = [
    google_compute_region_health_check.health_check
  ]
}