# 1. Creación de la Red VPC
resource "google_compute_network" "vpc_kubernetes" {
  name                    = "${var.network_name}-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

# 2. Creación de la Subred para GKE
resource "google_compute_subnetwork" "subnet_kubernetes" {
  name          = "${var.network_name}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc_kubernetes.id

  # Rangos secundarios para los pods y servicios de Kubernetes (VPC-nativo)
  secondary_ip_range {
    range_name    = "gke-rango-pods"
    ip_cidr_range = var.pods_cidr
  }

  secondary_ip_range {
    range_name    = "gke-rango-services"
    ip_cidr_range = var.services_cidr
  }
}

# 3. Regla de Firewall para permitir el tráfico de salida (Egress)
# Autopilot requiere esta regla para permitir que los nodos accedan a Internet
resource "google_compute_firewall" "allow_all_egress" {
  name    = "${var.network_name}-allow-egress"
  network = google_compute_network.vpc_kubernetes.name
  
  allow {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]
  # Aplicamos la regla a todos los nodos. GKE Autopilot usará etiquetas específicas.
  direction          = "EGRESS"
}

# --- Recurso del Clúster GKE Autopilot ---

# 4. Creación del Clúster GKE en modo Autopilot
resource "google_container_cluster" "autopilot_cluster" {
  name               = var.cluster_name
  location           = var.region
  network            = google_compute_network.vpc_kubernetes.name
  subnetwork         = google_compute_subnetwork.subnet_kubernetes.name
  
  # *** Habilitar el modo Autopilot ***
  enable_autopilot = true
  

  # Habilita el modo VPC-nativo (requerido y simplificado para Autopilot)
  ip_allocation_policy {
    cluster_secondary_range_name = google_compute_subnetwork.subnet_kubernetes.secondary_ip_range[0].range_name # Pods
    services_secondary_range_name = google_compute_subnetwork.subnet_kubernetes.secondary_ip_range[1].range_name # Services
  }

  # Configuración del clúster (por ejemplo, mantenimiento)
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  deletion_protection  = false
}