resource "google_composer_environment" "composer" {
  provider = google-beta
  name     = var.composer_env_name
  project  = var.project_id
  region   = var.region
  labels   = length(keys(var.labels)) < 0 ? null : var.labels

  lifecycle {
    ignore_changes = [
      labels,
    ]
  }
  config {
    environment_size = var.environment_size
    software_config {
      image_version = var.image_version
    }
    node_config {
      network         = var.network
      subnetwork      = var.subnetwork
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
      for_each = var.enable_software_config ? [{}] : []
      content {
        airflow_config_overrides = var.airflow_config_overrides
        pypi_packages            = var.pypi_packages
        env_variables            = var.env_variables
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
  timeouts {
    create = var.timeouts
  }
  depends_on = [
    google_project_iam_binding.composer_binding,
    google_project_iam_binding.serviceAccount_binding,
    google_project_iam_binding.binding,
    google_project_iam_member.project,
    google_compute_subnetwork_iam_member.cloudservices,
    google_compute_subnetwork_iam_member.container_engine_robot,
  ]
}

resource "google_project_iam_binding" "composer_binding" {
  project = var.project_id
  role    = "roles/composer.ServiceAgentV2Ext"
  members = [
    "serviceAccount:service-${data.google_project.service_project.number}@cloudcomposer-accounts.iam.gserviceaccount.com",
    "serviceAccount:${data.google_project.service_project.number}-compute@developer.gserviceaccount.com",
    "serviceAccount:composer-env-account@mahindra-datalake-prod-625956.iam.gserviceaccount.com"
  ]
}
resource "google_project_iam_binding" "serviceAccount_binding" {
  project = var.project_id
  role    = "roles/iam.serviceAccountAdmin"
  members = [
    "serviceAccount:service-${data.google_project.service_project.number}@cloudcomposer-accounts.iam.gserviceaccount.com",
    "serviceAccount:${data.google_project.service_project.number}-compute@developer.gserviceaccount.com",
    "serviceAccount:composer-env-account@mahindra-datalake-prod-625956.iam.gserviceaccount.com",
  ]
}
resource "google_service_account" "service_account" {
  project      = var.project_id
  account_id   = "composer-env-account"
  display_name = "Test Service Account for Composer Environment"
}
resource "google_project_iam_member" "composer-worker" {
  project = var.project_id
  role    = "roles/composer.worker"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}
data "google_project" "service_project" {
  project_id = var.project_id
}

# shared vpc
resource "google_project_iam_binding" "binding" {
  count   = var.shared_vpc ? 1 : 0
  project = var.host_project
  role    = "roles/composer.sharedVpcAgent"
  members = [
    "serviceAccount:service-${data.google_project.service_project.number}@cloudcomposer-accounts.iam.gserviceaccount.com",
    "serviceAccount:composer-env-account@mahindra-datalake-prod-625956.iam.gserviceaccount.com",
  ]
}
resource "google_project_iam_binding" "network_binding" {
  count   = var.shared_vpc ? 1 : 0
  project = var.host_project
  role    = "roles/compute.networkUser"
  members = [
    "serviceAccount:service-${data.google_project.service_project.number}@cloudcomposer-accounts.iam.gserviceaccount.com",
    "serviceAccount:composer-env-account@mahindra-datalake-prod-625956.iam.gserviceaccount.com",
  ]
}
resource "google_project_iam_binding" "network_binding2" {
  count   = var.shared_vpc ? 1 : 0
  project = var.host_project
  role    = "roles/composer.ServiceAgentV2Ext"
  members = [
    "serviceAccount:service-${data.google_project.service_project.number}@cloudcomposer-accounts.iam.gserviceaccount.com",
    "serviceAccount:composer-env-account@mahindra-datalake-prod-625956.iam.gserviceaccount.com"

  ]
}
resource "google_project_iam_member" "project" {
  count   = var.shared_vpc ? 1 : 0
  project = var.host_project
  role    = "roles/container.hostServiceAgentUser"
  member  = "serviceAccount:service-${data.google_project.service_project.number}@container-engine-robot.iam.gserviceaccount.com"
}
resource "google_compute_subnetwork_iam_member" "cloudservices" {
  count      = var.shared_vpc ? 1 : 0
  project    = var.host_project
  subnetwork = var.subnetwork
  role       = "roles/compute.networkUser"
  member     = "serviceAccount:${data.google_project.service_project.number}@cloudservices.gserviceaccount.com"
}
resource "google_compute_subnetwork_iam_member" "container_engine_robot" {
  count      = var.shared_vpc ? 1 : 0
  project    = var.host_project
  subnetwork = var.subnetwork
  role       = "roles/compute.networkUser"
  member     = "serviceAccount:service-${data.google_project.service_project.number}@container-engine-robot.iam.gserviceaccount.com"
}

