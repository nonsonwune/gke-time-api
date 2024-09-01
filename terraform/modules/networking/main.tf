resource "google_compute_network" "time_api_vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  project                 = var.project_id
}

resource "google_compute_subnetwork" "time_api_subnet" {
  name          = "time-api-subnet"
  region        = var.region
  network       = google_compute_network.time_api_vpc.self_link
  ip_cidr_range = "10.0.0.0/24"
  project       = var.project_id
}

resource "google_compute_router" "time_api_router" {
  name    = "time-api-router"
  region  = var.region
  network = google_compute_network.time_api_vpc.self_link
  project = var.project_id
}

resource "google_compute_router_nat" "time_api_nat" {
  name                               = "time-api-nat"
  router                             = google_compute_router.time_api_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  project                            = var.project_id
}

resource "google_compute_firewall" "internal" {
  name    = "time-api-allow-internal"
  network = google_compute_network.time_api_vpc.self_link
  project = var.project_id

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = [google_compute_subnetwork.time_api_subnet.ip_cidr_range]
}

resource "google_compute_firewall" "http" {
  name    = "time-api-allow-http"
  network = google_compute_network.time_api_vpc.self_link
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["gke-node", "time-api-gke"]
}

output "vpc_name" {
  value = google_compute_network.time_api_vpc.name
}

output "subnet_name" {
  value = google_compute_subnetwork.time_api_subnet.name
}
