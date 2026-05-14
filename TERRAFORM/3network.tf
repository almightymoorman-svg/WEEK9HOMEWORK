# 3-network.tf
# Creates the custom VPC, a single subnet, and the necessary firewall rules.
# Using a custom VPC (auto_create_subnetworks = false) so we control exactly
# what subnets exist — the default VPC creates subnets in every region which
# is unnecessary and creates a larger attack surface.

# --- VPC ---

resource "google_compute_network" "vpc" {
  name = var.network_name

  # Custom mode — we define subnets explicitly rather than letting GCP
  # auto-create one per region. Better for security and cost control.
  auto_create_subnetworks = false
}

# --- Subnet ---

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  network       = google_compute_network.vpc.id
  region        = var.region
  ip_cidr_range = var.subnet_cidr

  # Enable private Google access so instances without external IPs can still
  # reach Google APIs (Cloud Storage, Logging, etc.) without going through NAT
  private_ip_google_access = true
}

# --- Firewall Rules ---

# Allow HTTP traffic (port 80) to instances tagged "http-server"
# This covers both user traffic arriving from the LB and the LB itself
resource "google_compute_firewall" "allow_http" {
  name    = "${var.network_name}-allow-http"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  # Only applies to instances with this tag — avoids opening port 80 to
  # every VM in the VPC. The MIG instances will have this tag.
  target_tags   = ["http-server"]
  source_ranges = ["0.0.0.0/0"]

  description = "Allow inbound HTTP on port 80 to tagged instances"
}

# Allow GCP health check probes to reach instances.
# These two CIDR ranges are Google's dedicated health check infrastructure.
# Without this rule, health checks will fail and the LB won't send traffic.
# Source: https://cloud.google.com/load-balancing/docs/health-checks#firewall_rules
resource "google_compute_firewall" "allow_health_checks" {
  name    = "${var.network_name}-allow-health-checks"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  target_tags = ["http-server"]

  # These ranges are static and specific to Google's health check systems
  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16",
  ]

  description = "Allow GCP health check probes from Google's health check IP ranges"
}

# Allow SSH from IAP (Identity-Aware Proxy) for secure shell access.
# IAP tunnels SSH through Google's infrastructure so instances don't
# need a public IP or an open firewall to the entire internet.
# Source: https://cloud.google.com/iap/docs/using-tcp-forwarding
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "${var.network_name}-allow-iap-ssh"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags = ["http-server"]

  # 35.235.240.0/20 is the IAP tunnel IP range — only allowing SSH via IAP,
  # not directly from the internet
  source_ranges = ["35.235.240.0/20"]

  description = "Allow SSH via IAP — no direct internet SSH access needed"
}
