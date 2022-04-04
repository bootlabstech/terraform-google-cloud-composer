variable "name" {
  type        = string
  description = "The name of  Cloud Composer the Environment"
}

variable "project" {
  type        = string
  description = "Project ID where Cloud Composer Environment is created."
}

variable "region" {
  type        = string
  description = "Region where the Cloud Composer Environment is created."
}

variable "image_version" {
  type        = string
  description = "The version of the software running in the environment. This encapsulates both the version of Cloud Composer functionality and the version of Apache Airflow. It must match the regular expression composer-[0-9]+\\.[0-9]+(\\.[0-9]+)?-airflow-[0-9]+\\.[0-9]+(\\.[0-9]+.*)?."
}

#scheduler config

variable "scheduler_cpu" {
    type        = number
    description = "The number of CPUs for a single Airflow scheduler."
}

variable "scheduler_memory_gb" {
    type        = number
    description = "The amount of memory (GB) for a single Airflow scheduler."
}

variable "scheduler_storage_gb" {
    type        = number
    description = "The amount of storage (GB) for a single Airflow scheduler."
}

variable "scheduler_count" {
    type        = number
    description = "The number of schedulers count to be created."
}

# web_server config

variable "web_server_cpu" {
    type        = number
    description = "The number of CPUs for the Airflow web server."
}

variable "web_server_memory_gb" {
    type        = number
    description = "The amount of memory (GB) for the Airflow web server."
}

variable "web_server_storage_gb" {
    type        = number
    description = "The amount of storage (GB) for the Airflow web server."
}

# worker config

variable "worker_cpu" {
    type        = number
    description = "The number of CPUs for a single Airflow worker."
}

variable "worker_memory_gb" {
    type        = number
    description = "The amount of memory (GB) for a single Airflow worker."
}

variable "worker_storage_gb" {
    type        = number
    description = "The amount of storage (GB) for a single Airflow worker."
}

variable "worker_min_count" {
    type        = number
    description = "The minimum number of Airflow workers that the environment can run."
}

variable "worker_max_count" {
    type        = number
    description = "The maximum number of Airflow workers that the environment can run."
}

variable "environment_size" {
    type        = string
    description = " The environment size controls the performance parameters of the managed Cloud Composer infrastructure that includes the Airflow database. "
}

variable "network" {
    type = string
    description = "The ID of network"

}

variable "subnetwork" {
    type = string
    description = "The ID of subnetwork"
}

variable "service_account" {
    type = string
    description = "The service_account to be created and assign the roles."
}


// optional variables
variable "timeouts" {
    type = string
    description = "The time to take create resources"
}

