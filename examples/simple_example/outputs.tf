output "address" {
    description = "Address of L7 Load Balancer"
    value = module.network_loadbalancer_L7.address
}

output "forwarding_rule_ids" {
    description = "forwarding rule resources ids"
    value = module.network_loadbalancer_L7.forwarding_rule_ids
}

output "target_proxy_ids" {
    description = "Target proxy resources ids"
    value = module.network_loadbalancer_L7.target_proxy_ids
}

output "backend_service_ids" {
    description = "Backend service resources ids"
    value = module.network_loadbalancer_L7.backend_service_ids
}

output "url_map_ids" {
    description = "Url map resources ids"
        value = module.network_loadbalancer_L7.url_map_ids
}

output "health_check_ids" {
    description = "Health check resource ids"
    value = module.network_loadbalancer_L7.health_check_ids
}