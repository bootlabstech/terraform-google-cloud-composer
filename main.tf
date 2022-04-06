resource "google_composer_environment" "example" {
  provider = google-beta
  name     = var.name
  project  = var.project
  region   = var.region
  depends_on = [
    google_project_iam_binding.binding,
    google_project_iam_member.project,
    google_compute_subnetwork_iam_member.cloudservices,
    google_compute_subnetwork_iam_member.container_engine_robot
  ]
  config {

    software_config {
      image_version = var.image_version
    }
   
    workloads_config {
        
      scheduler {
        cpu        = var.scheduler_cpu
        memory_gb  = var.scheduler_memory_gb
        storage_gb = var.scheduler_storage_gb
        count      = var.scheduler_count
      }
      web_server {
        cpu        = var.web_server_cpu
        memory_gb  = var.web_server_memory_gb
        storage_gb = var.web_server_storage_gb
      }
      worker {
        cpu        = var.worker_cpu
        memory_gb  = var.worker_memory_gb
        storage_gb = var.worker_storage_gb
        min_count  = var.worker_min_count
        max_count  = var.worker_max_count
      }
    }
    environment_size = var.environment_size

    node_config {
      network         = var.network
      subnetwork      = var.subnetwork

      ip_allocation_policy {
        cluster_secondary_range_name = var.cluster_secondary_range_name
        services_secondary_range_name = var.services_secondary_range_name
      }
    }

    private_environment_config {
      enable_private_endpoint = var.enable_private_endpoint
      master_ipv4_cidr_block  = var.enable_private_endpoint ? var.master_ipv4_cidr_block : null
    }
    
  }  
}

resource "google_project_iam_binding" "binding" {
  project  =  var.project
  role = <<EOF
    {
    "roles/composer.ServiceAgentV2Ext",
    "roles/composer.sharedVpcAgent",
    "roles/composer.admin"
}
EOF
  members = var.members
}

data "google_project" "service_project" {
  project_id = var.project
}

resource "google_project_iam_member" "project" {
  project = var.host_project
  role    = "roles/container.hostServiceAgentUser"
  member = "serviceAccount:service-${data.google_project.service_project.number}@container-engine-robot.iam.gserviceaccount.com"
}


resource "google_compute_subnetwork_iam_member" "cloudservices" {
  project    = var.host_project
  subnetwork = var.subnetwork
  role       = "roles/compute.networkUser"
  member     = "serviceAccount:${data.google_project.service_project.number}@cloudservices.gserviceaccount.com"
}

resource "google_compute_subnetwork_iam_member" "container_engine_robot" {
  project    = var.host_project
  subnetwork = var.subnetwork
  role       = "roles/compute.networkUser"
  member     = "serviceAccount:service-${data.google_project.service_project.number}@container-engine-robot.iam.gserviceaccount.com"
}