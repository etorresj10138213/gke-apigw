variable "project_id" {
  description = "El ID de tu proyecto de GCP"
  type        = string
  default = "consalud-dev"
}

variable "region" {
  description = "La región de GCP donde se desplegará el clúster"
  type        = string
  default     = "us-east1"
}

variable "network_name" {
  description = "Nombre base para los recursos de red"
  type        = string
  default     = "gke-consalud-net"
}

variable "cluster_name" {
  description = "Nombre del clúster GKE Autopilot"
  type        = string
  default     = "gke-auto-consalud-apigw"
}

variable "subnet_cidr" {
  description = "Rango de IP para la subred principal"
  type        = string
  default     = "10.0.0.0/20"
}

variable "pods_cidr" {
  description = "Rango de IP secundario para los Pods de GKE"
  type        = string
  default     = "10.1.0.0/18"
}

variable "services_cidr" {
  description = "Rango de IP secundario para los Services de GKE"
  type        = string
  default     = "10.2.0.0/20"
}