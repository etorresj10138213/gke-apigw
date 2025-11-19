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
# (Se mantiene igual)
resource "google_compute_firewall" "allow_all_egress" {
  name    = "${var.network_name}-allow-egress"
  network = google_compute_network.vpc_kubernetes.name
  
  allow {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]
  direction          = "EGRESS"
}

# --- Recurso del Clúster GKE Estándar ---

# 4. Creación del Clúster GKE en modo Estándar (Cluster Master)
resource "google_container_cluster" "standard_cluster" {
  # *** CAMBIO 1: Cambiar el nombre del recurso (opcional, pero buena práctica) ***
  name               = var.cluster_name
  location           = var.region
  network            = google_compute_network.vpc_kubernetes.name
  subnetwork         = google_compute_subnetwork.subnet_kubernetes.name
  
  # *** CAMBIO CLAVE 2: Eliminar 'enable_autopilot = true' y el bloque de nodo por defecto ***
  initial_node_count = 1
  # Habilita el modo VPC-nativo (requerido)
  ip_allocation_policy {
    cluster_secondary_range_name = google_compute_subnetwork.subnet_kubernetes.secondary_ip_range[0].range_name # Pods
    services_secondary_range_name = google_compute_subnetwork.subnet_kubernetes.secondary_ip_range[1].range_name # Services
  }

  # Indicamos a GKE que NO cree el Node Pool por defecto,
  # ya que lo definiremos explícitamente a continuación.
  remove_default_node_pool = true 

  # Configuración del clúster (por ejemplo, mantenimiento)
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  deletion_protection  = false
}

# --- Recurso del Grupo de Nodos (Node Pool) ---

# 5. Definición del Grupo de Nodos para el Clúster Estándar
resource "google_container_node_pool" "primary_node_pool" {
  name       = "${var.cluster_name}-pool-01"
  location   = var.region
  cluster    = google_container_cluster.standard_cluster.name
  node_count = 3 # Número inicial de nodos
  
  node_config {
    machine_type = "e2-medium" # Tipo de máquina para los nodos
    disk_size_gb = 100         # Tamaño del disco de arranque
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  # Configuración de Autoescalado (ejemplo)
  autoscaling {
    min_node_count = 1
    max_node_count = 5
  }
}