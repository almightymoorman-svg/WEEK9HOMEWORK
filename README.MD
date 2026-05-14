# WEEK 9: Global Load Balancing, Cloud CDN, Cloud Armor Overview

This week focused on learning more about networking and security services inside Google Cloud. We mainly worked with Global Load Balancing, Cloud CDN, Cloud Armor, and Cloud NAT. The assignment was mostly about understanding how traffic moves through Google’s network, how caching improves performance, and how applications can be protected from bad traffic or attacks.

This repository contains the written Q&A section, the runbook, and the Terraform files used for the infrastructure setup.

---

# Files in this Repository

README.md  
Contains the overview of the assignment, notes, and resources used.

Q&A.md  
Contains the written responses for the assignment questions.

RUNBOOK.md  
Contains the group runbook for setting up the global external HTTPS load balancer.

terraform folder  
Contains the Terraform configuration files used to deploy the infrastructure resources.

Inside the terraform folder there are:

main.tf  
Main Terraform configuration.

variables.tf  
Variables used throughout the Terraform code.

outputs.tf  
Outputs generated after deployment.

network.tf  
VPC, subnet, and networking resources.

mig.tf  
Managed Instance Group configuration.

---

# Resources Used

Cloud NAT Docs  
Used to understand how private VM instances can still access the internet without needing public IP addresses.

GCP Private NAT Documentation  
Extra reading used for understanding NAT behavior and private access.

Setup Global External HTTPS Load Balancer  
Main reference used while writing the runbook and understanding the load balancer configuration.

Deep Dive on Global External HTTPS Load Balancer (Google Blog)  
Helped explain anycast and how Google routes traffic globally.

CDN - Content Delivery Network - Explained  
Watched before reading the Cloud CDN docs because I needed a better understanding of CDN concepts first.

Cloud CDN Product Page  
Used to confirm supported origin types and review the main features.

GeeksforGeeks: What is Google Cloud CDN?  
Supplemental explanation that helped clarify caching and TTL behavior.

Cloud CDN General Docs  
Used for the cache-control and TTL questions in the Q&A.

WAF basics  
Background reading before learning Cloud Armor.

Cloudflare WAF Glossary  
Helped explain the difference between a firewall and a WAF.

Cloud Armor Product Overview  
Used for understanding the main purpose of Cloud Armor.

Cloud Armor Docs  
Main reference for security rules, rate limiting, and reCAPTCHA related features.

Blog: When to Use Cloud Armor  
Used for understanding real world use cases.

Blog: Blocking the Largest Layer 7 DDoS Attack  
Helped explain Layer 7 attacks and why services like Cloud Armor matter.

GCP VPC Tutorial  
Reference used while building the VPC and subnet resources in Terraform.

---

# Notes

The Terraform files deploy the backend infrastructure including the VPC, firewall rules, and managed instance group. The actual load balancer configuration is mainly explained in the runbook because that part was completed through the Google Cloud console as part of the group section.

Some parts of the networking setup took a little while to understand, especially how backend services connect into the load balancer and how traffic flows between components, but testing it out helped make it easier to follow.

---

# Running Terraform

```bash
cd terraform/

terraform init

terraform validate

terraform apply
```

Requirements:
- Google Cloud project
- Billing enabled
- Authenticated credentials configured

Variables that need to be changed are located in variables.tf