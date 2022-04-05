resource "google_composer_environment" "example" {
  provider = google-beta
  name     = var.name
  project  = var.project
  region   = var.region
  depends_on = [
    google_project_iam_binding.binding
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
      service_account = var.service_account

    }
    
  }  
}

resource "google_project_iam_binding" "binding" {
  project  =  var.project
  role = "roles/composer.ServiceAgentV2Ext"
  members = var.members
}

