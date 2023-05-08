variable "name" {
  description = "The name of the load balancer"
  type        = string
}

variable "project_id" {
  description = "Project id of the load balancer"
  type        = string
}

variable "is_external" {
  description = "Specify whether the L7 load balancer is  external or not"
  type = bool
}

variable "region" {
  description = "The region of the Internal load balancer. If specified, Create regional load balancer"
  type = string
  default = null
}

variable "network" {
  description = "The URL of the network to which this load balancer belongs"
  type = string
  default = null
}

variable "impersonate_sa" {
  description = "Email of the service account to use for Terraform"
  type        = string
}

variable "validate_labels" {
  description = "validate labels"
  type        = map(string)
}



############################
## Frontend configuration ##
############################

variable "frontend_configs" {
  description = "Frontend configuration of L7 load balancer"
  type = map(object({
    description      = optional(string)
    protocol         = string                   # HTTP , HTTPS
    ip_version       = optional(string, "IPV4") # IPV4 , IPV6  External only
    ip_address       = optional(string)         # literal IP address , Existing Address resource (Ephemeral IP is assigned if null)
    port             = optional(number, 80)     # 80, 8080, 443
    ssl_policy       = optional(string)
    certificate_map  = optional(string)
    quic_negotiation = optional(string) # NONE(default) , ENABLE , DISABLE
    network          = optional(string) # Only self-link(shared vpc env)
    subnet = optional(string) # Internal only (Not Proxy-only subnet)
    allow_global_access = optional(bool) # Internal only
    service_label = optional(string) # Internal only
    service_directory_registration = optional(object({ # Internal only
      namespace = string
      service = string
    }))

  }))
  default = {}

  validation {
    condition = alltrue([for k,v in var.frontend_configs : v.protocol == "HTTP"|| v.protocol == "HTTPS"])
    #condition     = var.frontend_configs.protocol == "HTTP" || var.frontend_configs.protocol == "HTTPS"
    error_message = "Protocol must be HTTP or HTTPS"
  }

  validation {
    condition     = alltrue([for k,v in var.frontend_configs : v.port != 443 || v.protocol != "HTTP"])
    error_message = "443 port can only be specified when HTTPS protocol is set"
  }

  validation {
    condition     = alltrue([for k,v in var.frontend_configs : v.port != 80 || v.protocol != "HTTPS"])
    error_message = "80 port can only be specified when HTTP protocol is set"
  }

  validation {
    condition     = alltrue([for k,v in var.frontend_configs : v.port != 8080 || v.protocol != "HTTPS"])
    error_message = "8080 port can only be specified when HTTP protocol is set"
  }
}

variable "ssl_certificates" {
  description = "ssl certificates for existing, custom, managed certificates"
  type = object({
    certificate_ids = optional(list(string), []) # For Existing Cert
    custom_cert = optional(map(object({ # For creating Custom cert
      certificate = string
      private_key = string
      description = optional(string)
    })), {})
    managed_cert = optional(map(object({ # For creating Managed cert
      domains     = list(string)
      description = optional(string)
    })), {})
  })
  default  = {}
  nullable = false
}

###########################
## Backend configuration ##
###########################

variable "backend_services" {
  description = "Backend services configuration of L7 load balancer"
  type = map(object({

    #### General ####

    project_id      = optional(string) # For cross-project load balancing, Specify difference project with frontend (Internal, Regional LB only)
    description  = optional(string)
    backend_type = string # INSTANCE_GROUP , NEG
    protocol     = string # HTTP , HTTPS , HTTP2
    named_port   = optional(string)
    timeout_sec  = optional(number)
  

    #### Backends ####

    backends = list(object({
      group = string # fully-qualified URL of Instance Group or Network Endpoint Group
      balancing_mode = object({
        utilization = optional(object({                            # Only one of utilization or rate can be specified
          max_utilization              = optional(number) # 0.0 ~ 1.0
          max_connections              = optional(number) # Only one of max_connections or max_rps can be specified
          max_connections_per_instance = optional(number)
          max_rps_per_group            = optional(number)
          max_rps_per_instance         = optional(number)
        }))
        rate = optional(object({
          max_rps_per_group    = optional(number)
          max_rps_per_instance = optional(number)
        }))
        capacity = optional(number, 1) # 0.0 ~ 1.0 
      })
      description = optional(string)
    }))

    #### Cloud CDN ####

    cdn_policy = optional(object({
      enable_cloud_cdn = optional(bool, true)
      cache_mode       = optional(string, "CACHE_ALL_STATIC") # USE_ORIGIN_HEADERS , FORCE_CACHE_ALL , CACHE_ALL_STATIC(default)
      client_ttl_sec   = optional(number)                     # "0" means "always revalidate" ,  default value is 3600(1h)
      default_ttl_sec  = optional(number)                     # "0" means "always revalidate"
      max_ttl_sec      = optional(number)                     # "0" means "always revalidate"
      cache_key_policy = optional(object({
        include_protocol       = optional(bool, true)
        include_host           = optional(bool, true)
        include_query_string   = optional(bool, true)
        query_string_whitelist = optional(list(string)) # Either specify query_string_whitelist or query_string_blacklist, not both
        query_string_blacklist = optional(list(string)) # Either specify query_string_whitelist or query_string_blacklist, not both
        include_http_headers   = optional(list(string))
        include_named_cookies  = optional(list(string))
      }))
      serve_while_stale            = optional(bool)
      signed_url_cache_max_age_sec = optional(number)
      enable_negative_caching      = optional(bool)
      negative_caching_policy = optional(list(object({
        code    = optional(number)
        ttl_sec = optional(number)
      })))
    }))

    #### Health Check ####

    health_check = optional(list(string)) # Currently at most one health check can be specified

    #### Logging ####

    log_config = optional(object({
      enable      = optional(bool)
      sample_rate = optional(number) # 0.0 ~ 1.0 default is 1.0
    }))

    #### Security ####

    security_policy = optional(string)

    #### Session Affinity ####

    session_affinity                = optional(string) # NONE(default), CLIENT_IP, CLIENT_IP_PORT_PROTO, CLIENT_IP_PROTO, GENERATED_COOKIE, HEADER_FIELD, HTTP_COOKIE.
    affinity_cookie_ttl_sec         = optional(number) # Applicable if the session_affinity is GENERATED_COOKIE
    connection_draining_timeout_sec = optional(number)

    #### Traffic Policy ####

    locality_lb_policy = optional(string) # ROUND_ROBIN , LEAST_REQUEST , RING_HASH , RANDOM , ORIGINAL_DESTINATION , MAGLEV
    consistent_hash = optional(object({
      http_cookie = optional(object({ # Applicable if the sessionAffinity is set to HTTP_COOKIE
        name = optional(string)
        path = optional(string)
        ttl = optional(object({
          seconds = number           # 0 ~ 315,576,000,000
          nanos   = optional(number) # 0 ~ 999,999,999
        }))
      }))
      http_header_name  = optional(string) # Applicable if the sessionAffinity is set to HEADER_FIELD
      minimum_ring_size = optional(number) # default is 1024, Applicable if the locality_lb_policy is set to RING_HASH

    }))

    #### Circuit Breaker ####

    circuit_breakers = optional(object({ # Applicable only at Internal HTTP(S) LB
      max_requests_per_connection = optional(number)
      max_connections             = optional(number) # default is 1024
      max_pending_requests        = optional(number) # default is 1024
      max_requests                = optional(number) # default is 1024
      max_retries                 = optional(number) # default is 1
    }))

    #### Outlier Detection ####

    outlier_detection = optional(object({
      consecutive_errors = optional(number) # default is 5
      interval = optional(object({
        seconds = number           # 0 ~ 315,576,000,000
        nanos   = optional(number) # 0 ~ 999,999,999 with seconds 0
      }))
      base_ejection_time = optional(object({
        seconds = number           # 0 ~ 315,576,000,000 
        nanos   = optional(number) # 0 ~ 999,999,999 with seconds 0
      }))
      max_ejection_percent                  = optional(number) # default is 50
      success_rate_minimum_hosts            = optional(number) # default is 5
      success_rate_stdev_factor             = optional(number) # default is 1900
      success_rate_request_volume           = optional(number) # default is 100
      enforcing_consecutive_errors          = optional(number) # default is 0
      enforcing_success_rate                = optional(number) # default is 100
      consecutive_gateway_failure           = optional(number) # default is 5
      enforcing_consecutive_gateway_failure = optional(number) # default is 100
    }))

    ### Failover Policy #### 

    failover_policy = optional(object({
      disable_connection_drain_on_failover = optional(bool)
      drop_traffic_if_unhealthy = optional(bool)
      failover_ratio = optional(number) # 0 ~ 1
    }))

    #### Custom Headers #### (External only)

    custom_request_headers  = optional(list(string)) # ex : ["host: ${google_compute_global_network_endpoint.proxy.fqdn}"]
    custom_response_headers = optional(list(string)) # ex : ["X-Cache-Hit: {cdn_cache_status}"]

    #### IAP Configuration ####

    iap_config = optional(object({
      oauth2_client_id            = string
      oauth2_client_secret        = string
      oauth2_client_secret_sha256 = string
    }))
  }))
  default = {}
  validation {
    condition     = alltrue([for k,v in var.backend_services : v.protocol == "HTTP" || v.protocol == "HTTPS" || v.protocol == "HTTP2"])
    error_message = "Protocol must be HTTP or HTTPS or HTTP2"
  }
  validation {
    condition     = alltrue([for k,v in var.backend_services : v.session_affinity == "HTTP_COOKIE" || try(v.consistent_hash.http_cookie, null) == null])
    error_message = "http_cookie argument is applicable only if the session_affininity is set to HTTP_COOKIE"
  }
  validation {
    condition     = alltrue([for k,v in var.backend_services : v.session_affinity == "HEADER_FIELD" || try(v.consistent_hash.http_header_name, null) == null])
    error_message = "http_header_name argument is applicable only if the session_affininity is set to HEADER_FIELD"
  }
  validation {
    condition     = alltrue([for k,v in var.backend_services : v.locality_lb_policy == "RING_HASH" || try(v.consistent_hash.minimum_ring_size, null) == null])
    error_message = "minimum_ring_hash argument is applicable only if the localty_lb_policy is set to RING_HASH"
  }
}

################################
## HealthCheck configuration ###
################################

variable "healthcheck_config" {
  description = "Health Check configurations of L7 load balancer to create"
  type = map(object({
    description = optional(string)
    http = optional(object({
      host               = optional(string) # default is null (Public IP of the backend)
      port               = optional(number) # default is 80
      port_name          = optional(string) # InstanceGroup#NamedPort#name , If both port and port_name are defined, port takes precedence
      proxy_header       = optional(string) # NONE(default) , PROXY_V1
      request_path       = optional(string) # default is /
      response           = optional(string)
      port_specification = optional(string) # USE_FIXED_PORT , USE_NAMED_PORT , USE_SERVING_PORT
    }))
    https = optional(object({
      host               = optional(string) # default is null (Public IP of the backend)
      port               = optional(number) # default is 80
      port_name          = optional(string) # InstanceGroup#NamedPort#name , If both port and port_name are defined, port takes precedence
      proxy_header       = optional(string) # NONE(default) , PROXY_V1
      request_path       = optional(string) # default is /
      response           = optional(string)
      port_specification = optional(string) # USE_FIXED_PORT , USE_NAMED_PORT , USE_SERVING_PORT
    }))
    http2 = optional(object({
      host               = optional(string) # default is null (Public IP of the backend)
      port               = optional(number) # default is 80
      port_name          = optional(string) # InstanceGroup#NamedPort#name , If both port and port_name are defined, port takes precedence
      proxy_header       = optional(string) # NONE(default) , PROXY_V1
      request_path       = optional(string) # default is /
      response           = optional(string)
      port_specification = optional(string) # USE_FIXED_PORT , USE_NAMED_PORT , USE_SERVING_PORT
    }))
    enable_log          = optional(bool)   # default is false
    check_interval_sec  = optional(number) # default is 5
    timeout_sec         = optional(number) # default is 5
    healthy_threshold   = optional(number) # default is 2
    unhealthy_threshold = optional(number) # default is 2
  }))
  default = {}

  validation {
    condition     = alltrue([for k,v in var.healthcheck_config : v.timeout_sec <= v.check_interval_sec])
    error_message = "It is invalid for timeoutSec to have greater value than checkIntervalSec"
  }
}

####################
## Routing Rules ###
####################

variable "routing_rules" {
  description = "Routing rules of the L7 Load Balancer"
  type = map(object({

    description = optional(string)

    #### Default rule #####

    default_rule = object({
      default_backend = optional(string) # Specify just backend service except naming conventioins

      #### Route traffic to a single backend ####

      route_action = optional(object({
        url_rewrite = optional(object({
          host_rewrite        = optional(string)
          path_prefix_rewrite = optional(string)
        }))
      }))

      #### Redirect the client to different host/path ####

      url_redirect = optional(object({
        host          = optional(string)
        fullpath      = optional(string) #fullpath_redirect cannot be supplied together with prefix_redirect
        prefix        = optional(string)
        response_code = optional(string) # MOVED_PERMANENTLY_DEFAULT , FOUND , SEE_OTHER , TEMPORARY_REDIRECT , PERMANENT_REDIRECT
        https         = optional(bool)
        strip_query   = optional(bool)
      }))
    })

    #### Additional Rules ####

    additional_rules = optional(object({
      host_rules = optional(list(object({
        hosts        = list(string)
        path_matcher = string
      })))
      header_action = optional(object({
        request_headers_to_add = optional(object({
          name    = string
          value   = string
          replace = bool
        }))
        request_headers_to_remove = optional(list(string))
        response_headers_to_add = optional(object({
          name    = string
          value   = string
          replace = bool
        }))
        response_headers_to_remove = optional(list(string))
      }))
      path_matchers = optional(map(object({
        description     = optional(string)
        default_service = optional(string)
        default_url_redirect = optional(object({
          host          = optional(string)
          fullpath      = optional(string) #fullpath_redirect cannot be supplied together with prefix_redirect
          prefix        = optional(string)
          response_code = optional(string) # MOVED_PERMANENTLY_DEFAULT , FOUND , SEE_OTHER , TEMPORARY_REDIRECT , PERMANENT_REDIRECT
          https         = optional(bool)
          strip_query   = optional(bool)
        }))
        default_route_action = optional(object({
          cors_policy = optional(object({
            allow_credentials    = optional(bool)
            allow_headers        = optional(string)
            allow_methods        = optional(string)
            allow_origin_regexes = optional(list(string))
            allow_origins        = optional(list(string))
            disabled             = optional(bool)
            expose_headers       = optional(string)
            max_age              = optional(string)
          }))
          fault_injection_policy = optional(object({
            abort = optional(object({
              http_status = number # 200 ~ 599
              percentage  = number # 0.0 ~ 100.0
            }))
            delay = optional(object({
              fixed_delay = object({
                seconds = number           # 0 ~ 315,576,000,000 
                nanos   = optional(number) # 0 ~ 999,999,999 
              })
              percentage = number # 0.0 ~ 100.0
            }))
          }))
          request_mirror_policy = optional(object({
            backend_service = string
          }))
          retry_policy = optional(object({
            num_retries = optional(number)
            per_try_timeout = optional(object({
              seconds = number           # 0 ~ 315,576,000,000
              nanos   = optional(number) # 0 ~ 999,999,999
            }))
            retry_condition = optional(string) # 5xx , gateway-error , connect-failure , retriable-4xx , refused-stream , cancelled , deadline-exceeded , resource-exhausted , unavailable
          }))
          timeout = optional(object({
            seconds = number           # 0 ~ 315,576,000,000 default is 15
            nanos   = optional(number) # 0 ~ 999,999,999
          }))
          url_rewrite = optional(object({
            host_rewrite        = optional(string)
            path_prefix_rewrite = optional(string)
          }))
          weighted_backend_services = optional(list(object({
            backend_service = string
            weight          = number
            header_action = optional(object({
              request_headers_to_add = optional(object({
                name    = string
                value   = string
                replace = bool
              }))
              request_headers_to_remove = optional(list(string))
              response_headers_to_add = optional(object({
                name    = string
                value   = string
                replace = bool
              }))
              response_headers_to_remove = optional(list(string))
            }))
          })))
        }))
        path_rules = optional(list(object({
          service = optional(string) # If set, route_action.weighted_backend_service can't be set. Vice versa.
          paths   = list(string)     # Must start with / 
          url_redirect = optional(object({
            host          = optional(string)
            fullpath      = optional(string) #fullpath_redirect cannot be supplied together with prefix_redirect
            prefix        = optional(string)
            response_code = optional(string) # MOVED_PERMANENTLY_DEFAULT , FOUND , SEE_OTHER , TEMPORARY_REDIRECT , PERMANENT_REDIRECT
            https         = optional(bool)
            strip_query   = optional(bool)
          }))
          route_action = optional(object({
            cors_policy = optional(object({
              allow_credentials    = optional(bool)
              allow_headers        = optional(string)
              allow_methods        = optional(string)
              allow_origin_regexes = optional(list(string))
              allow_origins        = optional(list(string))
              disabled             = optional(bool)
              expose_headers       = optional(string)
              max_age              = optional(string)
            }))
            fault_injection_policy = optional(object({
              abort = optional(object({
                http_status = number # 200 ~ 599
                percentage  = number # 0.0 ~ 100.0
              }))
              delay = optional(object({
                fixed_delay = object({
                  seconds = number           # 0 ~ 315,576,000,000 
                  nanos   = optional(number) # 0 ~ 999,999,999 
                })
                percentage = number # 0.0 ~ 100.0
              }))
            }))
            request_mirror_policy = optional(object({
              backend_service = string
            }))
            retry_policy = optional(object({
              num_retries = optional(number)
              per_try_timeout = optional(object({
                seconds = number           # 0 ~ 315,576,000,000
                nanos   = optional(number) # 0 ~ 999,999,999
              }))
              retry_condition = optional(string) # 5xx , gateway-error , connect-failure , retriable-4xx , refused-stream , cancelled , deadline-exceeded , resource-exhausted , unavailable
            }))
            timeout = optional(object({
              seconds = number           # 0 ~ 315,576,000,000 default is 15
              nanos   = optional(number) # 0 ~ 999,999,999
            }))
            url_rewrite = optional(object({
              host_rewrite        = optional(string)
              path_prefix_rewrite = optional(string)
            }))
            weighted_backend_services = optional(list(object({
              backend_service = string
              weight          = number
              header_action = optional(object({
                request_headers_to_add = optional(object({
                  name    = string
                  value   = string
                  replace = bool
                }))
                request_headers_to_remove = optional(list(string))
                response_headers_to_add = optional(object({
                  name    = string
                  value   = string
                  replace = bool
                }))
                response_headers_to_remove = optional(list(string))
              }))
            })))
          }))
        })))
        route_rules = optional(list(object({
          priority = number           # 0 ~ 2147483647
          service  = optional(string) # If set, route_action.weighted_backend_service can't be set. Vice versa.
          header_action = optional(object({
            request_headers_to_add = optional(object({
              name    = string
              value   = string
              replace = bool
            }))
            request_headers_to_remove = optional(list(string))
            response_headers_to_add = optional(object({
              header_name  = string
              header_value = string
              replace      = bool
            }))
            response_headers_to_remove = optional(list(string))
          }))
          match_rules = optional(list(object({
            path = optional(object({
              value = string
              type  = string # FULL , PREFIX , REGEX
            }))
            ignore_case = optional(bool, false)
            headers = optional(list(object({
              name = string
              match = optional(object({
                value        = string
                type         = optional(string) # EXACT, PRESENT , PREFIX , REGEX , SUFFIX
                invert_match = optional(bool)
                range_match = optional(object({
                  range_start = string
                  range_end   = string
                }))
              }))
            })))
            metadata_filters = optional(list(object({
              labels         = map(string)
              match_criteria = string # MATCH_ANY , MATCH_ALL
            })))
            query_parameters = optional(list(object({
              match = object({
                name  = string
                value = string
                type  = string # EXACT , PRESENT , REGEX
              })
            })))

          })))
          route_action = optional(object({
            cors_policy = optional(object({
              allow_credentials    = optional(bool)
              allow_headers        = optional(string)
              allow_methods        = optional(string)
              allow_origin_regexes = optional(list(string))
              allow_origins        = optional(list(string))
              disabled             = optional(bool)
              expose_headers       = optional(string)
              max_age              = optional(string)
            }))
            fault_injection_policy = optional(object({
              abort = optional(object({
                http_status = number # 200 ~ 599
                percentage  = number # 0.0 ~ 100.0
              }))
              delay = optional(object({
                fixed_delay = object({
                  seconds = number           # 0 ~ 315,576,000,000 
                  nanos   = optional(number) # 0 ~ 999,999,999 
                })
                percentage = number # 0.0 ~ 100.0
              }))
            }))
            request_mirror_policy = optional(object({
              backend_service = string
            }))
            retry_policy = optional(object({
              num_retries = optional(number)
              per_try_timeout = optional(object({
                seconds = number           # 0 ~ 315,576,000,000
                nanos   = optional(number) # 0 ~ 999,999,999
              }))
              retry_condition = optional(string) # 5xx , gateway-error , connect-failure , retriable-4xx , refused-stream , cancelled , deadline-exceeded , resource-exhausted , unavailable
            }))
            timeout = optional(object({
              seconds = number           # 0 ~ 315,576,000,000 default is 15
              nanos   = optional(number) # 0 ~ 999,999,999
            }))
            url_rewrite = optional(object({
              host_rewrite        = optional(string)
              path_prefix_rewrite = optional(string)
            }))
            weighted_backend_services = optional(list(object({
              backend_service = string
              weight          = number
              header_action = optional(object({
                request_headers_to_add = optional(object({
                  name    = string
                  value   = string
                  replace = bool
                }))
                request_headers_to_remove = optional(list(string))
                response_headers_to_add = optional(object({
                  name    = string
                  value   = string
                  replace = bool
                }))
                response_headers_to_remove = optional(list(string))
              }))
            })))
          }))
          url_redirect = optional(object({
            host          = optional(string)
            fullpath      = optional(string) #fullpath_redirect cannot be supplied together with prefix_redirect
            prefix        = optional(string)
            response_code = optional(string) # MOVED_PERMANENTLY_DEFAULT , FOUND , SEE_OTHER , TEMPORARY_REDIRECT , PERMANENT_REDIRECT
            https         = optional(bool)
            strip_query   = optional(bool)
          }))
        })))
        header_action = optional(object({
          request_headers_to_add = optional(object({
            name    = string
            value   = string
            replace = bool
          }))
          request_headers_to_remove = optional(list(string))
          response_headers_to_add = optional(object({
            header_name  = string
            header_value = string
            replace      = bool
          }))
          response_headers_to_remove = optional(list(string))
        }))
      })))
    }),{})

    #### Test ####

    test = optional(list(object({
        host = string
        path = string
        service = string
        description = optional(string)
    })),[])
  }))
  default = null
}




