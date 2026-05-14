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

[Cloud NAT Docs](https://cloud.google.com/nat/docs/overview)  
Used to understand how private VM instances can still access the internet without needing public IP addresses.

[GCP Private NAT Documentation  ](https://cloud.google.com/nat/docs/private-nat)
Extra reading used for understanding NAT behavior and private access.

[Setup Global External HTTPS Load Balancer ](https://cloud.google.com/load-balancing/docs/https) 
Main reference used while writing the runbook and understanding the load balancer configuration.

[Deep Dive on Global External HTTPS Load Balancer (Google Blog)](https://cloud.google.com/blog/products/networking/how-googles-global-load-balancer-works)  
Helped explain anycast and how Google routes traffic globally.

[CDN - Content Delivery Network - Explained](https://www.youtube.com/watch?v=Bsq5cKkS33I)  
Watched before reading the Cloud CDN docs because I needed a better understanding of CDN concepts first.

[Cloud CDN Product Page](https://cloud.google.com/cdn)  
Used to confirm supported origin types and review the main features.

[GeeksforGeeks: What is Google Cloud CDN?](https://www.geeksforgeeks.org/what-is-google-cloud-cdn/)  
Supplemental explanation that helped clarify caching and TTL behavior.

[Cloud CDN General Docs  ](https://cloud.google.com/cdn/docs)
Used for the cache-control and TTL questions in the Q&A.

[WAF basics ](https://owasp.org/www-community/Web_Application_Firewall) 
Background reading before learning Cloud Armor.

https://www.cloudflare.com/learning/ddos/glossary/web-application-firewall-waf/  
Helped explain the difference between a firewall and a WAF.

[Cloud Armor Product Overview  ](https://cloud.google.com/armor/docs)
Used for understanding the main purpose of Cloud Armor.

[Cloud Armor Docs  ](https://cloud.google.com/armor/docs)
Main reference for security rules, rate limiting, and reCAPTCHA related features.

[Blog: When to Use Cloud Armor ](https://cloud.google.com/blog/products/identity-security/when-to-use-cloud-armor) 
Used for understanding real world use cases.

[Blog: Blocking the Largest Layer 7 DDoS Attac](https://cloud.google.com/blog/products/identity-security/how-google-cloud-blocked-largest-layer-7-ddos-attack)k  
Helped explain Layer 7 attacks and why services like Cloud Armor matter.

[GCP VPC Tutorial  ](https://www.youtube.com/watch?v=q0RpPCcVaFo)
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