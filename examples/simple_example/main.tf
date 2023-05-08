
module "network_loadbalancer_L7" {
  source = "../.."
  region = "asia-northeast3"
  name = "lb-clouddevops-test"
  project_id = "prj-sandbox-devops-9999"
  network = "default"
  is_external = true
  frontend_configs = {
    test = {
      description = "test"
      network = "projects/prj-p-s-shared-base-373107/global/networks/vpc-p-s-shared-base"  # Only self-link(shared vpc env, host project)
      subnet = "projects/prj-sandbox-devops-9999/regions/asia-northeast3/subnetworks/sb-p-s-shared-threetier-aisa-northeast-3" # self-link(shared vpc env, service project)
      #ip_address = "10.0.0.1"
      #ip_version = "IPV4"
      port = 80
      protocol = "HTTP"
      #quic_negotiation = "NONE"
    }
  }
  backend_services = {
    backendservice1 = {
      project_id = "prj-sandbox-devops-9999"
      affinity_cookie_ttl_sec = 1
      backend_type = "INSTANCE_GROUP"
      backends = [ {
        balancing_mode = {
          capacity = 1
          rate = {
            max_rps_per_group = 1
          }
        }
        description = "test"
        group = "https://www.googleapis.com/compute/v1/projects/prj-sandbox-devops-9999/zones/asia-northeast3-a/instanceGroups/gke-gke-dev-clouddevops-sandbo-pool-1-64276d8a-grp"
      } ] 
      health_check = ["hc-hc1"]
      log_config = {
        enable = false
        sample_rate = 1
      }
      named_port = "http"
      protocol = "HTTP"
    }
  }
  routing_rules = {
    "rule1" = {
      default_rule = {
        default_backend = "backendservice1"
      }
      description = "test routing rule 1"
    }
  }
  healthcheck_config = {
    "hc1" = {
      check_interval_sec = 1
      enable_log = false
      healthy_threshold = 1
      http = {
        host = "test"
        port = 80
        # port_name = "value"
        # port_specification = "value"
        # proxy_header = "value"
        # request_path = "value"
        # response = "value"
      }
      timeout_sec = 1
      unhealthy_threshold = 1
    }
    "hc2" = {
      check_interval_sec = 1
      enable_log = false
      healthy_threshold = 1
      http = {
        host = "test"
        port = 80
        # port_name = "value"
        # port_specification = "value"
        # proxy_header = "value"
        # request_path = "value"
        # response = "value"
      }
      timeout_sec = 1
      unhealthy_threshold = 1
    }    
  }
}
