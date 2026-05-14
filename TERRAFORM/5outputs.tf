# 5-outputs.tf
# Outputs useful values after apply — these are the things you'll actually
# need when wiring up the LB or verifying the deployment.

output "vpc_name" {
  description = "Name of the custom VPC created"
  value       = google_compute_network.vpc.name
}

output "subnet_name" {
  description = "Name of the subnet"
  value       = google_compute_subnetwork.subnet.name
}

output "subnet_cidr" {
  description = "CIDR range of the subnet"
  value       = google_compute_subnetwork.subnet.ip_cidr_range
}

output "instance_template_name" {
  description = "Name of the instance template used by the MIG"
  value       = google_compute_instance_template.web.name
}

output "mig_name" {
  description = "Name of the Managed Instance Group — use this when selecting the backend in the LB setup"
  value       = google_compute_instance_group_manager.mig.name
}

output "mig_self_link" {
  description = "Self-link of the MIG — useful for referencing in other configs or scripts"
  value       = google_compute_instance_group_manager.mig.self_link
}

output "mig_zone" {
  description = "Zone the MIG is deployed in"
  value       = google_compute_instance_group_manager.mig.zone
}

output "named_port" {
  description = "Named port configured on the MIG — must match the LB backend service port configuration"
  value       = "http:80"
}
