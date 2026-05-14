# 4-mig.tf
# Defines the instance template and the Managed Instance Group (MIG).
# The MIG is the backend that the load balancer (set up via ClickOps per the runbook)
# will point at. The instance template defines what each VM in the group looks like.

# --- Instance Template ---

resource "google_compute_instance_template" "web" {
  name         = var.instance_template_name
  machine_type = var.machine_type
  region       = var.region

  # The instance template is immutable after creation — Terraform will create
  # a new one and update the MIG if anything here changes
  lifecycle {
    create_before_destroy = true
  }

  # Boot disk — Debian 12 is stable and commonly used in class
  disk {
    source_image = "debian-cloud/debian-12"
    auto_delete  = true # Delete disk when instance is deleted
    boot         = true
    disk_size_gb = 10 # Minimum size to keep costs down; more than enough for Apache
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.subnet.id

    # No external IP — instances are private, traffic comes through the LB
    # If you need outbound internet access, add Cloud NAT to the subnet
  }

  # Startup script — installs Apache and serves a simple page
  # Used to verify the LB is routing and the health check is working
  metadata = {
    startup-script = <<-EOF
      #!/bin/bash
      apt-get update -y
      apt-get install -y apache2
      systemctl start apache2
      systemctl enable apache2
      # Write a simple page that shows the hostname so we can verify LB is distributing traffic
      echo "<h1>Hello from $(hostname)</h1>" > /var/www/html/index.html
    EOF
  }

  # Tag used by firewall rules — matches the target_tags in network.tf
  tags = ["http-server"]

  service_account {
    # Use the default compute service account
    # In production you'd create a least-privilege SA, but default is fine for this demo
    scopes = ["cloud-platform"]
  }
}

# --- Managed Instance Group ---

resource "google_compute_instance_group_manager" "mig" {
  name = var.mig_name
  zone = var.zone

  # Links the MIG to the instance template defined above
  version {
    instance_template = google_compute_instance_template.web.id
  }

  # Base name for instances created by this MIG (e.g., hw8-mig-xxxx)
  base_instance_name = var.mig_name

  # Named port — this is required for the load balancer backend service
  # to know which port to forward traffic to on the instances
  # Must match what you configure in the LB backend service (protocol port mapping)
  named_port {
    name = "http"
    port = 80
  }
}

# --- Autoscaler ---

resource "google_compute_autoscaler" "mig_autoscaler" {
  name   = "${var.mig_name}-autoscaler"
  zone   = var.zone
  target = google_compute_instance_group_manager.mig.id

  autoscaling_policy {
    min_replicas    = var.mig_min_replicas
    max_replicas    = var.mig_max_replicas
    cooldown_period = 60 # Seconds to wait after scaling before evaluating again

    # Scale based on CPU utilization — when average CPU across the group
    # exceeds 60%, add instances; when it drops well below, remove them
    cpu_utilization {
      target = 0.6 # 60% CPU target — standard starting point for web workloads
    }
  }
}
