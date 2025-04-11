resource "google_composer_environment" "composer" {
  provider = google-beta
  name     = var.name
  project  = var.project_id
  region   = var.region
  labels   = length(keys(var.labels)) < 0 ? null : var.labels
  lifecycle {
    ignore_changes = [
      labels, config[0].software_config[0].pypi_packages
    ]
  }
  config {
    environment_size = var.environment_size
    # software_config {
    #   image_version = var.image_version
      
    # }
    node_config {
      network         = var.network
      subnetwork      = var.subnetwork
      enable_ip_masq_agent = true
      service_account = google_service_account.service_account.email
      dynamic "ip_allocation_policy" {
        for_each = var.use_ip_allocation_policy ? [1] : []
        content {
          cluster_secondary_range_name  = var.cluster_secondary_range_name
          services_secondary_range_name = var.services_secondary_range_name
        }
      }
    }
    encryption_config {
      kms_key_name = var.kms_key_name
    }
     
    dynamic "software_config" {
    for_each = [1]
    content {
      image_version = var.image_version
      
 # Only set these values if enable_software_config is true
      airflow_config_overrides = var.enable_software_config ? var.airflow_config_overrides : null
      pypi_packages = var.enable_software_config ? var.pypi_packages : null
      env_variables = var.enable_software_config ? var.env_variables : null
    }
  }
    dynamic "private_environment_config" {
      for_each = var.use_private_environment ? [{}] : []
      content {
        #enable_private_endpoint               = var.enable_private_endpoint
        master_ipv4_cidr_block                 = var.master_ipv4_cidr
        cloud_sql_ipv4_cidr_block              = var.cloud_sql_ipv4_cidr
        cloud_composer_network_ipv4_cidr_block = var.cloud_composer_network_ipv4_cidr_block
      }
    }
    dynamic "maintenance_window" {
      for_each = var.use_maintenance_window ? [{}] : []
      content {
        start_time = var.maintenance_start_time
        end_time   = var.maintenance_end_time
        recurrence = var.maintenance_recurrence
      }
    }
  }
  # timeouts {
  #   create = var.timeouts
  # }
  depends_on = [
    google_project_iam_binding.composer1_binding,
    # google_project_iam_binding.composer2_binding,
    # google_project_iam_binding.composer3_binding,
    google_project_iam_binding.serviceAccount_binding,
    # google_project_iam_binding.network_binding,
    # google_project_iam_member.host_gke_member,
    # google_compute_subnetwork_iam_member.host_cloudservices_member,
    # google_compute_subnetwork_iam_member.host_container_engine_robot_member,
    google_project_iam_member.composer-worker,
    google_project_iam_binding.kms_cloud_composer
  ]
}


# project level permissions

resource "google_service_account" "service_account" {
  project      = var.project_id
  account_id   = "composer-env-account"
  display_name = "Test Service Account for Composer Environment"
}
resource "google_project_iam_member" "composer-worker" {
  project = var.project_id
   lifecycle {
    ignore_changes = [ member ]
  }
  role    = "roles/composer.worker"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}
resource "google_project_iam_binding" "composer1_binding" {
  project = var.project_id
  role    = "roles/composer.ServiceAgentV2Ext"
   lifecycle {
    ignore_changes = [ members ]
  }
  members = [
    "serviceAccount:service-${data.google_project.service_project.number}@cloudcomposer-accounts.iam.gserviceaccount.com",
    "serviceAccount:${data.google_project.service_project.number}-compute@developer.gserviceaccount.com",
    "serviceAccount:${google_service_account.service_account.email}",
  ]
}
resource "google_project_iam_binding" "serviceAccount_binding" {
  project = var.project_id
  role    = "roles/iam.serviceAccountAdmin"
  lifecycle {
    ignore_changes = [ members ]
  }
  members = [
    "serviceAccount:service-${data.google_project.service_project.number}@cloudcomposer-accounts.iam.gserviceaccount.com",
    "serviceAccount:${data.google_project.service_project.number}-compute@developer.gserviceaccount.com",
    "serviceAccount:${google_service_account.service_account.email}",
  ]
}


# host project level permissions

data "google_project" "service_project" {
  project_id = var.project_id
}

# resource "google_project_iam_binding" "composer2_binding" {
#   count   = var.shared_vpc ? 1 : 0
#   project = var.host_project
#   role    = "roles/composer.sharedVpcAgent"
#    lifecycle {
#     ignore_changes = [ members ]
#   }
#   members = [
#     "serviceAccount:service-${data.google_project.service_project.number}@cloudcomposer-accounts.iam.gserviceaccount.com",
#     "serviceAccount:${google_service_account.service_account.email}",
#   ]
# }
# resource "google_project_iam_binding" "network_binding" {
#   count   = var.shared_vpc ? 1 : 0
#   project = var.host_project
#    lifecycle {
#     ignore_changes = [ members ]
#   }
#   role    = "roles/compute.networkUser"
#   members = [
#     "serviceAccount:service-${data.google_project.service_project.number}@cloudcomposer-accounts.iam.gserviceaccount.com",
#     "serviceAccount:${google_service_account.service_account.email}",
#   ]
# }
# resource "google_project_iam_binding" "composer3_binding" {
#   count   = var.shared_vpc ? 1 : 0
#   project = var.host_project
#    lifecycle {
#     ignore_changes = [ members ]
#   }
#   role    = "roles/composer.ServiceAgentV2Ext"
#   members = [
#     "serviceAccount:service-${data.google_project.service_project.number}@cloudcomposer-accounts.iam.gserviceaccount.com",
#     "serviceAccount:${google_service_account.service_account.email}",
#   ]
# }
# resource "google_project_iam_member" "host_gke_member" {
#   count   = var.shared_vpc ? 1 : 0
#   project = var.host_project
#    lifecycle {
#     ignore_changes = [ member ]
#   }
#   role    = "roles/container.hostServiceAgentUser"
#   member  = "serviceAccount:service-${data.google_project.service_project.number}@container-engine-robot.iam.gserviceaccount.com"
# }
# resource "google_compute_subnetwork_iam_member" "host_cloudservices_member" {
#   count      = var.shared_vpc ? 1 : 0
#   project    = var.host_project
#   region = var.region
#    lifecycle {
#     ignore_changes = [ member ]
#   }
#   subnetwork = var.subnetwork
#   role       = "roles/compute.networkUser"
#   member     = "serviceAccount:${data.google_project.service_project.number}@cloudservices.gserviceaccount.com"
# }
# resource "google_compute_subnetwork_iam_member" "host_container_engine_robot_member" {
#   count      = var.shared_vpc ? 1 : 0
#   project    = var.host_project
#   region = var.region
#    lifecycle {
#     ignore_changes = [ member ]
#   }
#   subnetwork = var.subnetwork
#   role       = "roles/compute.networkUser"
#   member     = "serviceAccount:service-${data.google_project.service_project.number}@container-engine-robot.iam.gserviceaccount.com"
# }

resource "google_project_iam_binding" "kms_cloud_composer" {
  count   = 1
  project =var.project_id
   lifecycle {
    ignore_changes = [ members ]
  }
  role    = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members = [
    "serviceAccount:service-${data.google_project.service_project.number}@cloudcomposer-accounts.iam.gserviceaccount.com",
    "serviceAccount:service-${data.google_project.service_project.number}@container-engine-robot.iam.gserviceaccount.com",
    "serviceAccount:service-${data.google_project.service_project.number}@gcp-sa-artifactregistry.iam.gserviceaccount.com",
    "serviceAccount:service-${data.google_project.service_project.number}@gcp-sa-pubsub.iam.gserviceaccount.com",
    "serviceAccount:service-${data.google_project.service_project.number}@compute-system.iam.gserviceaccount.com",
    "serviceAccount:service-${data.google_project.service_project.number}@gcp-sa-cloud-sql.iam.gserviceaccount.com",
    "serviceAccount:service-${data.google_project.service_project.number}@gs-project-accounts.iam.gserviceaccount.com",
  ]
}


