resource "google_compute_url_map" "url_map" {
    for_each = var.region == null ? var.routing_rules : {}
    name = "lb-${var.name}"
    project = var.project_id
    description = each.value.description
    default_service = local.global_external_backend_service.id
    dynamic "default_route_action" {
        for_each = each.value.default_rule.route_action != null ? [each.value.default_rule.route_action] : []
        iterator = action
        content {
            url_rewrite {
              host_rewrite = action.url_rewrite.host_rewrite
              path_prefix_rewrite = action.url_rewrite.path_prefix_rewrite
            }
        }
    }
    dynamic "default_url_redirect" {
        for_each = each.value.default_rule.url_redirect != null ? [each.value.default_rule.url_redirect] : []
        iterator = redirect
        content {
            host_redirect = redirect.value.host
            https_redirect = redirect.value.https
            prefix_redirect = redirect.value.prefix
            redirect_response_code = redirect.value.response_code
            path_redirect = redirect.value.fullpath
            strip_query = redirect.value.strip_query
        }
    }
    dynamic "host_rule" {
        for_each = each.value.additional_rules.host_rules != null ? {
            for k,v in each.value.additional_rules.host_rules : k => v
        } : {}
        iterator = rule
        content {
            hosts = rule.value.hosts
            path_matcher = rule.value.path_matcher
        }
    }
    dynamic "header_action" {
        for_each = each.value.additional_rules.header_action != null ? [each.value.additional_rules.header_action] : []
        iterator = action
        content {
            dynamic "request_headers_to_add" {
                for_each = action.value.request_headers_to_add != null ? [action.value.request_headers_to_add] : []
                iterator = config
                content {
                    header_name = config.value.name
                    header_value = config.value.value
                    replace = config.value.replace
                }
            }
            request_headers_to_remove = action.value.request_headers_to_remove
            dynamic "response_headers_to_add" {
                for_each = action.value.response_headers_to_add != null ? [ action.value.response_headers_to_add] : []
                iterator = config
                content {
                    header_name = config.value.name
                    header_value = config.value.value
                    replace = config.value.replace
                }
            }
            response_headers_to_remove = action.value.response_headers_to_remove
        }
    }
    dynamic "path_matcher" {
        for_each = each.value.additional_rules.path_matchers != null ? each.value.additional_rules.path_matchers : {}
        iterator = config
        content {
            name = config.key
            description = config.value.description
            default_service = config.value.default_service
            dynamic "default_url_redirect" {
                for_each = config.value.url_redirect != null ? [config.value.url_redirect] : []
                iterator = redirect
                content {
                    host_redirect = redirect.value.host
                    https_redirect = redirect.value.https
                    prefix_redirect = redirect.value.prefix
                    redirect_response_code = redirect.value.response_code
                    path_redirect = redirect.value.fullpath
                    strip_query = redirect.value.strip_query
                }
            }
            dynamic "default_route_action" {
                for_each = config.value.default_route_action != null ? [config.value.default_route_action] : []
                iterator = action
                content {
                    dynamic "cors_policy" {
                        for_each = action.value.cors_policy != null ? [action.value.cors_policy] : []
                        iterator = policy
                        content {
                            allow_credentials = policy.value.allow_credentials
                            allow_headers = policy.value.allow_headers
                            allow_methods = policy.value.allow_methods
                            allow_origins = policy.value.allow_origins
                            allow_origin_regexes = policy.value.allow_origin_regexes
                            disabled = policy.value.disabled
                            max_age = policy.value.max_age
                            expose_headers = policy.value.expose_headers
                        }
                    }
                    dynamic "fault_injection_policy" {
                        for_each = action.value.fault_injection_policy != null ? [action.value.fault_injection_policy] : []
                        iterator = policy
                        content {
                            dynamic "abort" {
                                for_each = policy.value.abort != null ? [policy.value.abort] : []
                                content {
                                    http_status = abort.value.http_status
                                    percentage = abort.value.percentage
                                }
                            }
                            dynamic "delay" {
                                for_each = policy.value.delay != null ? [policy.value.delay] : []
                                content {
                                    fixed_delay {
                                      seconds = delay.value.fixed_delay.seconds
                                      nanos = delay.value.fixed_delay.nanos
                                    }
                                    percentage = policy.value.percentage
                                }
                            }
                        }
                    }
                    dynamic "request_mirror_policy" {
                        for_each = action.value.request_mirror_policy != null ? [action.value.request_mirror_policy] : []
                        iterator = policy
                        content {
                            backend_service = policy.value.backend_service
                        }
                    }
                    dynamic "retry_policy" {
                        for_each = action.value.retry_policy != null ? [action.value.retry_policy] : []
                        iterator = policy
                        content {
                            num_retries = policy.value.num_retries
                            dynamic "per_try_timeout" {
                                for_each = policy.value.per_try_timeout != null ? [policy.value.per_try_timeout] : []
                                iterator = config
                                content {
                                    seconds = config.value.seconds
                                    nanos = config.value.nanos
                                }
                            }
                            retry_conditions = policy.value.retry_condition
                        }
                    }
                    dynamic "timeout" {
                        for_each = action.value.timeout != null ? [action.value.timeout] : []
                        content {
                            seconds = timeout.value.seconds
                            nanos = timeout.value.nanos
                        }
                    }
                    dynamic "url_rewrite" {
                        for_each = action.value.url_rewrite != null ? [action.value.url_rewrite] : []
                        iterator = config
                        content {
                            host_rewrite = config.value.host_rewrite
                            path_prefix_rewrite = config.value.path_prefix_rewrite
                        }
                    }
                    dynamic "weighted_backend_services" {
                        for_each = {
                            for k,v in action.value.weighted_backend_services : k => v
                        }
                        iterator = service
                        content {
                            backend_service =  "bs-${var.name}-${service.value.backend_service}"
                            weight = service.value.weight
                            dynamic "header_action" {
                                for_each = service.value.additional_rules.header_action != null ? [service.value.additional_rules.header_action] : []
                                iterator = action
                                content {
                                    dynamic "request_headers_to_add" {
                                        for_each = action.value.request_headers_to_add != null ? [action.value.request_headers_to_add] : []
                                        iterator = config
                                        content {
                                            header_name = config.value.name
                                            header_value = config.value.value
                                            replace = config.value.replace
                                        }
                                    }
                                    request_headers_to_remove = action.value.request_headers_to_remove
                                    dynamic "response_headers_to_add" {
                                        for_each = action.value.response_headers_to_add != null ? [ action.value.response_headers_to_add] : []
                                        iterator = config
                                        content {
                                            header_name = config.value.name
                                            header_value = config.value.value
                                            replace = config.value.replace
                                        }
                                    }
                                    response_headers_to_remove = action.value.response_headers_to_remove
                                }
                            }                          
                        }
                    }

                }
            }
            dynamic "path_rule" {
                for_each = {
                    for k,v in config.value.path_rules : k => v
                }
                iterator = rule
                content {
                    service = rule.value.service
                    paths = rule.value.paths
                    dynamic "url_redirect" {
                        for_each = rule.value.url_redirect != null ? [rule.value.url_redirect] : []
                        iterator = redirect
                        content {
                            host_redirect = redirect.value.host
                            https_redirect = redirect.value.https
                            prefix_redirect = redirect.value.prefix
                            redirect_response_code = redirect.value.response_code
                            path_redirect = redirect.value.fullpath
                            strip_query = redirect.value.strip_query
                        }
                    }                    
                    dynamic "route_action" {
                        for_each = rule.value.route_action != null ? [rule.value.route_action] : []
                        iterator = action
                        content {
                            dynamic "cors_policy" {
                                for_each = action.value.cors_policy != null ? [action.value.cors_policy] : []
                                iterator = policy
                                content {
                                    allow_credentials = policy.value.allow_credentials
                                    allow_headers = policy.value.allow_headers
                                    allow_methods = policy.value.allow_methods
                                    allow_origins = policy.value.allow_origins
                                    allow_origin_regexes = policy.value.allow_origin_regexes
                                    disabled = policy.value.disabled
                                    max_age = policy.value.max_age
                                    expose_headers = policy.value.expose_headers
                                }
                            }
                            dynamic "fault_injection_policy" {
                                for_each = action.value.fault_injection_policy != null ? [action.value.fault_injection_policy] : []
                                iterator = policy
                                content {
                                    dynamic "abort" {
                                        for_each = policy.value.abort != null ? [policy.value.abort] : []
                                        content {
                                            http_status = abort.value.http_status
                                            percentage = abort.value.percentage
                                        }
                                    }
                                    dynamic "delay" {
                                        for_each = policy.value.delay != null ? [policy.value.delay] : []
                                        content {
                                            fixed_delay {
                                            seconds = delay.value.fixed_delay.seconds
                                            nanos = delay.value.fixed_delay.nanos
                                            }
                                            percentage = policy.value.percentage
                                        }
                                    }
                                }
                            }
                            dynamic "request_mirror_policy" {
                                for_each = action.value.request_mirror_policy != null ? [action.value.request_mirror_policy] : []
                                iterator = policy
                                content {
                                    backend_service = policy.value.backend_service
                                }
                            }
                            dynamic "retry_policy" {
                                for_each = action.value.retry_policy != null ? [action.value.retry_policy] : []
                                iterator = policy
                                content {
                                    num_retries = policy.value.num_retries
                                    dynamic "per_try_timeout" {
                                        for_each = policy.value.per_try_timeout != null ? [policy.value.per_try_timeout] : []
                                        iterator = config
                                        content {
                                            seconds = config.value.seconds
                                            nanos = config.value.nanos
                                        }
                                    }
                                    retry_conditions = policy.value.retry_condition
                                }
                            }
                            dynamic "timeout" {
                                for_each = action.value.timeout != null ? [action.value.timeout] : []
                                content {
                                    seconds = timeout.value.seconds
                                    nanos = timeout.value.nanos
                                }
                            }
                            dynamic "url_rewrite" {
                                for_each = action.value.url_rewrite != null ? [action.value.url_rewrite] : []
                                iterator = config
                                content {
                                    host_rewrite = config.value.host_rewrite
                                    path_prefix_rewrite = config.value.path_prefix_rewrite
                                }
                            }
                            dynamic "weighted_backend_services" {
                                for_each = {
                                    for k,v in action.value.weighted_backend_services : k => v
                                }
                                iterator = service
                                content {
                                    backend_service =  "bs-${var.name}-${service.value.backend_service}"
                                    weight = service.value.weight
                                    dynamic "header_action" {
                                        for_each = service.value.additional_rules.header_action != null ? [service.value.additional_rules.header_action] : []
                                        iterator = action
                                        content {
                                            dynamic "request_headers_to_add" {
                                                for_each = action.value.request_headers_to_add != null ? [action.value.request_headers_to_add] : []
                                                iterator = config
                                                content {
                                                    header_name = config.value.name
                                                    header_value = config.value.value
                                                    replace = config.value.replace
                                                }
                                            }
                                            request_headers_to_remove = action.value.request_headers_to_remove
                                            dynamic "response_headers_to_add" {
                                                for_each = action.value.response_headers_to_add != null ? [ action.value.response_headers_to_add] : []
                                                iterator = config
                                                content {
                                                    header_name = config.value.name
                                                    header_value = config.value.value
                                                    replace = config.value.replace
                                                }
                                            }
                                            response_headers_to_remove = action.value.response_headers_to_remove
                                        }
                                    }                          
                                }
                            }

                        }
                    }                    
                }
            }
            dynamic "route_rules" {
                for_each = {
                    for k,v in config.value.route_rules : k => v
                }
                iterator = rule
                content {
                    priority = rule.value.priority
                    service = rule.value.service
                    dynamic "header_action" {
                        for_each = rule.value.header_action != null ? [rule.value.header_action] : []
                        iterator = action
                        content {
                            dynamic "request_headers_to_add" {
                                for_each = action.value.request_headers_to_add != null ? [action.value.request_headers_to_add] : []
                                iterator = config
                                content {
                                    header_name = config.value.name
                                    header_value = config.value.value
                                    replace = config.value.replace
                                }
                            }
                            request_headers_to_remove = action.value.request_headers_to_remove
                            dynamic "response_headers_to_add" {
                                for_each = action.value.response_headers_to_add != null ? [ action.value.response_headers_to_add] : []
                                iterator = config
                                content {
                                    header_name = config.value.name
                                    header_value = config.value.value
                                    replace = config.value.replace
                                }
                            }
                            response_headers_to_remove = action.value.response_headers_to_remove
                        }
                    }
                    dynamic "route_action" {
                        for_each = rule.value.route_action != null ? [rule.value.route_action] : []
                        iterator = action
                        content {
                            dynamic "cors_policy" {
                                for_each = action.value.cors_policy != null ? [action.value.cors_policy] : []
                                iterator = policy
                                content {
                                    allow_credentials = policy.value.allow_credentials
                                    allow_headers = policy.value.allow_headers
                                    allow_methods = policy.value.allow_methods
                                    allow_origins = policy.value.allow_origins
                                    allow_origin_regexes = policy.value.allow_origin_regexes
                                    disabled = policy.value.disabled
                                    max_age = policy.value.max_age
                                    expose_headers = policy.value.expose_headers
                                }
                            }
                            dynamic "fault_injection_policy" {
                                for_each = action.value.fault_injection_policy != null ? [action.value.fault_injection_policy] : []
                                iterator = policy
                                content {
                                    dynamic "abort" {
                                        for_each = policy.value.abort != null ? [policy.value.abort] : []
                                        content {
                                            http_status = abort.value.http_status
                                            percentage = abort.value.percentage
                                        }
                                    }
                                    dynamic "delay" {
                                        for_each = policy.value.delay != null ? [policy.value.delay] : []
                                        content {
                                            fixed_delay {
                                            seconds = delay.value.fixed_delay.seconds
                                            nanos = delay.value.fixed_delay.nanos
                                            }
                                            percentage = policy.value.percentage
                                        }
                                    }
                                }
                            }
                            dynamic "request_mirror_policy" {
                                for_each = action.value.request_mirror_policy != null ? [action.value.request_mirror_policy] : []
                                iterator = policy
                                content {
                                    backend_service =  "bs-${var.name}-${policy.value.backend_service}"
                                }
                            }
                            dynamic "retry_policy" {
                                for_each = action.value.retry_policy != null ? [action.value.retry_policy] : []
                                iterator = policy
                                content {
                                    num_retries = policy.value.num_retries
                                    dynamic "per_try_timeout" {
                                        for_each = policy.value.per_try_timeout != null ? [policy.value.per_try_timeout] : []
                                        iterator = config
                                        content {
                                            seconds = config.value.seconds
                                            nanos = config.value.nanos
                                        }
                                    }
                                    retry_conditions = policy.value.retry_condition
                                }
                            }
                            dynamic "timeout" {
                                for_each = action.value.timeout != null ? [action.value.timeout] : []
                                content {
                                    seconds = timeout.value.seconds
                                    nanos = timeout.value.nanos
                                }
                            }
                            dynamic "url_rewrite" {
                                for_each = action.value.url_rewrite != null ? [action.value.url_rewrite] : []
                                iterator = config
                                content {
                                    host_rewrite = config.value.host_rewrite
                                    path_prefix_rewrite = config.value.path_prefix_rewrite
                                }
                            }
                            dynamic "weighted_backend_services" {
                                for_each = {
                                    for k,v in action.value.weighted_backend_services : k => v
                                }
                                iterator = service
                                content {
                                    backend_service =  "bs-${var.name}-${service.value.backend_service}"
                                    weight = service.value.weight
                                    dynamic "header_action" {
                                        for_each = service.value.additional_rules.header_action != null ? [service.value.additional_rules.header_action] : []
                                        iterator = action
                                        content {
                                            dynamic "request_headers_to_add" {
                                                for_each = action.value.request_headers_to_add != null ? [action.value.request_headers_to_add] : []
                                                iterator = config
                                                content {
                                                    header_name = config.value.name
                                                    header_value = config.value.value
                                                    replace = config.value.replace
                                                }
                                            }
                                            request_headers_to_remove = action.value.request_headers_to_remove
                                            dynamic "response_headers_to_add" {
                                                for_each = action.value.response_headers_to_add != null ? [ action.value.response_headers_to_add] : []
                                                iterator = config
                                                content {
                                                    header_name = config.value.name
                                                    header_value = config.value.value
                                                    replace = config.value.replace
                                                }
                                            }
                                            response_headers_to_remove = action.value.response_headers_to_remove
                                        }
                                    }                          
                                }
                            }

                        }
                    }
                    dynamic "url_redirect" {
                        for_each = rule.value.url_redirect != null ? [rule.value.url_redirect] : []
                        iterator = redirect
                        content {
                            host_redirect = redirect.value.host
                            https_redirect = redirect.value.https
                            prefix_redirect = redirect.value.prefix
                            redirect_response_code = redirect.value.response_code
                            path_redirect = redirect.value.fullpath
                            strip_query = redirect.value.strip_query
                        }
                    } 
                    dynamic "match_rules" {
                        for_each = {
                            for k,v in rule.value.match_rules : k => v
                        }
                        iterator = config
                        content {
                            full_path_match = try(config.value.path.type, null) == "FULL" ? config.value.path.value : null
                            prefix_match =  try(config.value.path.type, null) == "PREFIX" ? config.value.path.value : null
                            regex_match = try(config.value.path.type, null) == "REGEX" ? config.value.path.value : null
                            ignore_case = config.value.ignore_case
                            dynamic "metadata_filters" {
                                for_each = {
                                    for k,v in config.value.metadata_filters : k => v
                                }
                                iterator = filter
                                content {
                                    filter_labels {
                                      name = filter.value.labels.key
                                      value = filter.value.labels.value
                                    }
                                    filter_match_criteria = filter.value.match_criteria
                                }
                            }
                            dynamic "query_parameter_matches" {
                                for_each = {
                                    for k,v in config.value.query_parameters : k => v
                                }
                                iterator = query
                                content {
                                    name = query.value.match.name
                                    exact_match = try(query.value.match.type, null) == "EXACT" ?  query.value.match.value : null
                                    present_match = try(query.value.match.type, null) == "PRESENT" ? query.value.match.value : null
                                    regex_match = try(query.value.match.type == "REGEX", null) ? query.value.match.value : null
                                }
                            }
                            dynamic "header_matches" {
                                for_each = {
                                    for k,v in config.value.headers : k => v
                                }
                                iterator = header
                                content {
                                    header_name = header.value.name
                                    exact_match = try(header.value.type, null) == "EXACT" ? header.value.value : null
                                    present_match = try(header.value.type, null) == "PRESENT" ? header.value.value : null
                                    prefix_match = try(header.value.type, null) == "PREFIX" ? header.value.value : null
                                    suffix_match = try(header.value.type, null) == "SUFFIX" ? header.value.value : null
                                    regex_match = try(header.value.type, null) == "REGEX" ? header.value.value : null
                                    invert_match = header.value.invert_match
                                    dynamic "range_match" {
                                        for_each = header.value.range_match != null ? [header.value.range_match] : []
                                        iterator = range
                                        content {
                                            range_start = range.value.range_start
                                            range_end = range.value.range_end
                                        }
                                    }
                                }
                            }
                        }
                    }                                                               
                }
            }
            dynamic "header_action" {
                for_each = config.value.header_action != null ? [config.value.header_action] : []
                iterator = action
                content {
                    dynamic "request_headers_to_add" {
                        for_each = action.value.request_headers_to_add != null ? [action.value.request_headers_to_add] : []
                        iterator = config
                        content {
                            header_name = config.value.name
                            header_value = config.value.value
                            replace = config.value.replace
                        }
                    }
                    request_headers_to_remove = action.value.request_headers_to_remove
                    dynamic "response_headers_to_add" {
                        for_each = action.value.response_headers_to_add != null ? [ action.value.response_headers_to_add] : []
                        iterator = config
                        content {
                            header_name = config.value.name
                            header_value = config.value.value
                            replace = config.value.replace
                        }
                    }
                    response_headers_to_remove = action.value.response_headers_to_remove
                }
            }
        }
    }
    dynamic "test" {
        for_each = {
            for k,v in each.value.test : k => v
        }
        content {
            host = test.value.host
            path = test.value.path
            service = test.value.service
            description = test.value.description
        }
    }

    depends_on = [
      google_compute_backend_service.global_external_backend
    ]


}

##############################################################################################################################################

resource "google_compute_region_url_map" "url_map" {
    for_each = var.region == null ? {} :var.routing_rules
    name = "lb-${var.name}"
    region = var.region
    project = var.project_id
    description = each.value.description
    default_service = try(local.region_external_backend_service.id, local.region_internal_backend_service.id)  
    dynamic "default_route_action" {
        for_each = each.value.default_rule.route_action != null ? [each.value.default_rule.route_action] : []
        iterator = action
        content {
            url_rewrite {
              host_rewrite = action.url_rewrite.host_rewrite
              path_prefix_rewrite = action.url_rewrite.path_prefix_rewrite
            }
        }
    }
    dynamic "default_url_redirect" {
        for_each = each.value.default_rule.url_redirect != null ? [each.value.default_rule.url_redirect] : []
        iterator = redirect
        content {
            host_redirect = redirect.value.host
            https_redirect = redirect.value.https
            prefix_redirect = redirect.value.prefix
            redirect_response_code = redirect.value.response_code
            path_redirect = redirect.value.fullpath
            strip_query = redirect.value.strip_query
        }
    }
    dynamic "host_rule" {
        for_each = each.value.additional_rules.host_rules != null ? {
            for k,v in each.value.additional_rules.host_rules : k => v
        } : {}
        iterator = rule
        content {
            hosts = rule.value.hosts
            path_matcher = rule.value.path_matcher
        }
    }
    dynamic "path_matcher" {
        for_each = each.value.additional_rules.path_matchers != null ? each.value.additional_rules.path_matchers : {}
        iterator = config
        content {
            name = config.key
            description = config.value.description
            default_service = config.value.default_service
            dynamic "default_url_redirect" {
                for_each = config.value.default_url_redirect != null ? [config.value.default_url_redirect] : []
                iterator = redirect
                content {
                    host_redirect = redirect.value.host
                    https_redirect = redirect.value.https
                    prefix_redirect = redirect.value.prefix
                    redirect_response_code = redirect.value.response_code
                    path_redirect = redirect.value.fullpath
                    strip_query = redirect.value.strip_query
                }
            }
            dynamic "path_rule" {
                for_each =  config.value.path_rules != null ? {
                    for k,v in config.value.path_rules : k => v
                } : {}
                iterator = rule
                content {
                    service = rule.value.service
                    paths = rule.value.paths
                    dynamic "url_redirect" {
                        for_each = rule.value.url_redirect != null ? [rule.value.url_redirect] : []
                        iterator = redirect
                        content {
                            host_redirect = redirect.value.host
                            https_redirect = redirect.value.https
                            prefix_redirect = redirect.value.prefix
                            redirect_response_code = redirect.value.response_code
                            path_redirect = redirect.value.fullpath
                            strip_query = redirect.value.strip_query
                        }
                    }                    
                    dynamic "route_action" {
                        for_each = rule.value.route_action != null ? [rule.value.route_action] : []
                        iterator = action
                        content {
                            dynamic "cors_policy" {
                                for_each = action.value.cors_policy != null ? [action.value.cors_policy] : []
                                iterator = policy
                                content {
                                    allow_credentials = policy.value.allow_credentials
                                    allow_headers = policy.value.allow_headers
                                    allow_methods = policy.value.allow_methods
                                    allow_origins = policy.value.allow_origins
                                    allow_origin_regexes = policy.value.allow_origin_regexes
                                    disabled = policy.value.disabled
                                    max_age = policy.value.max_age
                                    expose_headers = policy.value.expose_headers
                                }
                            }
                            dynamic "fault_injection_policy" {
                                for_each = action.value.fault_injection_policy != null ? [action.value.fault_injection_policy] : []
                                iterator = policy
                                content {
                                    dynamic "abort" {
                                        for_each = policy.value.abort != null ? [policy.value.abort] : []
                                        content {
                                            http_status = abort.value.http_status
                                            percentage = abort.value.percentage
                                        }
                                    }
                                    dynamic "delay" {
                                        for_each = policy.value.delay != null ? [policy.value.delay] : []
                                        content {
                                            fixed_delay {
                                            seconds = delay.value.fixed_delay.seconds
                                            nanos = delay.value.fixed_delay.nanos
                                            }
                                            percentage = policy.value.percentage
                                        }
                                    }
                                }
                            }
                            dynamic "request_mirror_policy" {
                                for_each = action.value.request_mirror_policy != null ? [action.value.request_mirror_policy] : []
                                iterator = policy
                                content {
                                    backend_service = policy.value.backend_service
                                }
                            }
                            dynamic "retry_policy" {
                                for_each = action.value.retry_policy != null ? [action.value.retry_policy] : []
                                iterator = policy
                                content {
                                    num_retries = policy.value.num_retries
                                    dynamic "per_try_timeout" {
                                        for_each = policy.value.per_try_timeout != null ? [policy.value.per_try_timeout] : []
                                        iterator = config
                                        content {
                                            seconds = config.value.seconds
                                            nanos = config.value.nanos
                                        }
                                    }
                                    retry_conditions = policy.value.retry_condition
                                }
                            }
                            dynamic "timeout" {
                                for_each = action.value.timeout != null ? [action.value.timeout] : []
                                content {
                                    seconds = timeout.value.seconds
                                    nanos = timeout.value.nanos
                                }
                            }
                            dynamic "url_rewrite" {
                                for_each = action.value.url_rewrite != null ? [action.value.url_rewrite] : []
                                iterator = config
                                content {
                                    host_rewrite = config.value.host_rewrite
                                    path_prefix_rewrite = config.value.path_prefix_rewrite
                                }
                            }
                            dynamic "weighted_backend_services" {
                                for_each = {
                                    for k,v in action.value.weighted_backend_services : k => v
                                }
                                iterator = service
                                content {
                                    backend_service = service.value.backend_service
                                    weight = service.value.weight
                                    dynamic "header_action" {
                                        for_each = service.value.additional_rules.header_action != null ? [service.value.additional_rules.header_action] : []
                                        iterator = action
                                        content {
                                            dynamic "request_headers_to_add" {
                                                for_each = action.value.request_headers_to_add != null ? [action.value.request_headers_to_add] : []
                                                iterator = config
                                                content {
                                                    header_name = config.value.name
                                                    header_value = config.value.value
                                                    replace = config.value.replace
                                                }
                                            }
                                            request_headers_to_remove = action.value.request_headers_to_remove
                                            dynamic "response_headers_to_add" {
                                                for_each = action.value.response_headers_to_add != null ? [ action.value.response_headers_to_add] : []
                                                iterator = config
                                                content {
                                                    header_name = config.value.name
                                                    header_value = config.value.value
                                                    replace = config.value.replace
                                                }
                                            }
                                            response_headers_to_remove = action.value.response_headers_to_remove
                                        }
                                    }                          
                                }
                            }

                        }
                    }                    
                }
            }
            dynamic "route_rules" {
                for_each = {
                    for k,v in config.value.route_rules : k => v
                }
                iterator = rule
                content {
                    priority = rule.value.priority
                    service = rule.value.service
                    dynamic "header_action" {
                        for_each = rule.value.header_action != null ? [rule.value.header_action] : []
                        iterator = action
                        content {
                            dynamic "request_headers_to_add" {
                                for_each = action.value.request_headers_to_add != null ? [action.value.request_headers_to_add] : []
                                iterator = config
                                content {
                                    header_name = config.value.name
                                    header_value = config.value.value
                                    replace = config.value.replace
                                }
                            }
                            request_headers_to_remove = action.value.request_headers_to_remove
                            dynamic "response_headers_to_add" {
                                for_each = action.value.response_headers_to_add != null ? [ action.value.response_headers_to_add] : []
                                iterator = config
                                content {
                                    header_name = config.value.name
                                    header_value = config.value.value
                                    replace = config.value.replace
                                }
                            }
                            response_headers_to_remove = action.value.response_headers_to_remove
                        }
                    }
                    dynamic "route_action" {
                        for_each = rule.value.route_action != null ? [rule.value.route_action] : []
                        iterator = action
                        content {
                            dynamic "cors_policy" {
                                for_each = action.value.cors_policy != null ? [action.value.cors_policy] : []
                                iterator = policy
                                content {
                                    allow_credentials = policy.value.allow_credentials
                                    allow_headers = policy.value.allow_headers
                                    allow_methods = policy.value.allow_methods
                                    allow_origins = policy.value.allow_origins
                                    allow_origin_regexes = policy.value.allow_origin_regexes
                                    disabled = policy.value.disabled
                                    max_age = policy.value.max_age
                                    expose_headers = policy.value.expose_headers
                                }
                            }
                            dynamic "fault_injection_policy" {
                                for_each = action.value.fault_injection_policy != null ? [action.value.fault_injection_policy] : []
                                iterator = policy
                                content {
                                    dynamic "abort" {
                                        for_each = policy.value.abort != null ? [policy.value.abort] : []
                                        content {
                                            http_status = abort.value.http_status
                                            percentage = abort.value.percentage
                                        }
                                    }
                                    dynamic "delay" {
                                        for_each = policy.value.delay != null ? [policy.value.delay] : []
                                        content {
                                            fixed_delay {
                                            seconds = delay.value.fixed_delay.seconds
                                            nanos = delay.value.fixed_delay.nanos
                                            }
                                            percentage = policy.value.percentage
                                        }
                                    }
                                }
                            }
                            dynamic "request_mirror_policy" {
                                for_each = action.value.request_mirror_policy != null ? [action.value.request_mirror_policy] : []
                                iterator = policy
                                content {
                                    backend_service = policy.value.backend_service
                                }
                            }
                            dynamic "retry_policy" {
                                for_each = action.value.retry_policy != null ? [action.value.retry_policy] : []
                                iterator = policy
                                content {
                                    num_retries = policy.value.num_retries
                                    dynamic "per_try_timeout" {
                                        for_each = policy.value.per_try_timeout != null ? [policy.value.per_try_timeout] : []
                                        iterator = config
                                        content {
                                            seconds = config.value.seconds
                                            nanos = config.value.nanos
                                        }
                                    }
                                    retry_conditions = policy.value.retry_condition
                                }
                            }
                            dynamic "timeout" {
                                for_each = action.value.timeout != null ? [action.value.timeout] : []
                                content {
                                    seconds = timeout.value.seconds
                                    nanos = timeout.value.nanos
                                }
                            }
                            dynamic "url_rewrite" {
                                for_each = action.value.url_rewrite != null ? [action.value.url_rewrite] : []
                                iterator = config
                                content {
                                    host_rewrite = config.value.host_rewrite
                                    path_prefix_rewrite = config.value.path_prefix_rewrite
                                }
                            }
                            dynamic "weighted_backend_services" {
                                for_each = {
                                    for k,v in action.value.weighted_backend_services : k => v
                                }
                                iterator = service
                                content {
                                    backend_service = service.value.backend_service
                                    weight = service.value.weight
                                    dynamic "header_action" {
                                        for_each = service.value.header_action != null ? [service.value.header_action] : []
                                        iterator = action
                                        content {
                                            dynamic "request_headers_to_add" {
                                                for_each = action.value.request_headers_to_add != null ? [action.value.request_headers_to_add] : []
                                                iterator = config
                                                content {
                                                    header_name = config.value.name
                                                    header_value = config.value.value
                                                    replace = config.value.replace
                                                }
                                            }
                                            request_headers_to_remove = action.value.request_headers_to_remove
                                            dynamic "response_headers_to_add" {
                                                for_each = action.value.response_headers_to_add != null ? [ action.value.response_headers_to_add] : []
                                                iterator = config
                                                content {
                                                    header_name = config.value.name
                                                    header_value = config.value.value
                                                    replace = config.value.replace
                                                }
                                            }
                                            response_headers_to_remove = action.value.response_headers_to_remove
                                        }
                                    }                          
                                }
                            }

                        }
                    }
                    dynamic "url_redirect" {
                        for_each = rule.value.url_redirect != null ? [rule.value.url_redirect] : []
                        iterator = redirect
                        content {
                            host_redirect = redirect.value.host
                            https_redirect = redirect.value.https
                            prefix_redirect = redirect.value.prefix
                            redirect_response_code = redirect.value.response_code
                            path_redirect = redirect.value.fullpath
                            strip_query = redirect.value.strip_query
                        }
                    } 
                    dynamic "match_rules" {
                        for_each = {
                            for k,v in rule.value.match_rules : k => v
                        }
                        iterator = config
                        content {
                            full_path_match = try(config.value.path.type, null) == "FULL" ? config.value.path.value : null
                            prefix_match =  try(config.value.path.type, null) == "PREFIX" ? config.value.path.value : null
                            regex_match = try(config.value.path.type, null) == "REGEX" ? config.value.path.value : null
                            ignore_case = config.value.ignore_case
                            dynamic "metadata_filters" {
                                for_each = config.value.metadata_filters != null ? {
                                    for k,v in config.value.metadata_filters : k => v
                                } : {}
                                iterator = filter
                                content {
                                    filter_labels {
                                      name = filter.value.labels.key
                                      value = filter.value.labels.value
                                    }
                                    filter_match_criteria = filter.value.match_criteria
                                }
                            }
                            dynamic "query_parameter_matches" {
                                for_each = config.value.query_parameters != null ? {
                                    for k,v in config.value.query_parameters : k => v
                                } : {}
                                iterator = query
                                content {
                                    name = query.value.match.name
                                    exact_match = try(query.value.match.type, null) == "EXACT" ?  query.value.match.value : null
                                    present_match = try(query.value.match.type, null) == "PRESENT" ? query.value.match.value : null
                                    regex_match = try(query.value.match.type == "REGEX", null) ? query.value.match.value : null
                                }
                            }
                            dynamic "header_matches" {
                                for_each = config.value.headers != null ? {
                                    for k,v in config.value.headers : k => v
                                } : {}
                                iterator = header
                                content {
                                    header_name = header.value.name
                                    exact_match = try(header.value.type, null) == "EXACT" ? header.value.value : null
                                    present_match = try(header.value.type, null) == "PRESENT" ? header.value.value : null
                                    prefix_match = try(header.value.type, null) == "PREFIX" ? header.value.value : null
                                    suffix_match = try(header.value.type, null) == "SUFFIX" ? header.value.value : null
                                    regex_match = try(header.value.type, null) == "REGEX" ? header.value.value : null
                                    invert_match = header.value.invert_match
                                    dynamic "range_match" {
                                        for_each = header.value.range_match != null ? [header.value.range_match] : []
                                        iterator = range
                                        content {
                                            range_start = range.value.range_start
                                            range_end = range.value.range_end
                                        }
                                    }
                                }
                            }
                        }
                    }                                                               
                }
            }
        }
    }
    dynamic "test" {
        for_each = {
            for k,v in each.value.test : k => v
        }
        content {
            host = test.value.host
            path = test.value.path
            service = test.value.service
            description = test.value.description
        }
    }

    depends_on = [
      google_compute_region_backend_service.regional_external_backend,
      google_compute_region_backend_service.regional_internal_backend
    ]


}