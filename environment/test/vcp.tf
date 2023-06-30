module "gcp-network" {
  source = "terraform-google-modules/network/google"
  version = ">= 4.0.1"

  project_id = var.project
  network_name = "vpc-01"
  routing_mode = "REGIONAL"

  depends_on = [ 
    google_project_service.gcp_services ]

  subnets = [
    {
      subnet_name   = var.subnet_name
      subnet_ip     = "10.100.100.0/28"
      subnet_region = var.region
      subnet_private_access = true
    },
  ]

  secondary_ranges = {
    (var.subnet_name) = [
      {
        range_name    = var.ip_range_pods_name
        ip_cidr_range = "10.101.0.0/20"
      },
      {
        range_name    = var.ip_range_services_name
        ip_cidr_range = "10.102.0.0/20"
      },
    ]
  }

  firewall_rules = [
    {
      name    = "allow-ssh-ingress"
      direction = "INGRESS"
      ranges   = ["0.0.0.0/0"]
      allow = [{
        protocol = "tcp"
        ports    = ["22"]
      }]
      },
      {
        name    = "allow-internal-ingress"
        direction = "INGRESS"
        ranges   = ["0.0.0.0/0"]

        allow = [{
          protocol = "tcp"
          ports    = ["0-65535"]
        },
        {
          protocol = "udp"
          ports    = ["0-65535"]
        },
        {
          protocol = "icmp"
          ports    = null
        }]
      },
      {
        name    = "allow-gossip-ingress"
        direction = "INGRESS"
        ranges   = ["0.0.0.0/0"]
        allow = [{
          protocol = "tcp"
          ports    = ["8443"]
        }]
      },
      {
        name   = "allow-icmp-ingress"
        direction = "INGRESS"
        ranges   = ["0.0.0.0/0"]
        allow = [{
          protocol = "icmp"
          ports    = null
        }]
      },
      {
        name   = "allow-http-https-ingress"
        direction = "INGRESS"
        ranges   = ["0.0.0.0/0"]
        allow = [{
          protocol = "tcp"
          ports    = ["80"]
        },
        {
          protocol = "tcp"
          ports    = ["443"]
        }]

      },
      {
        name    = "allow-vault-ingress"
        direction = "INGRESS"
        ranges   = ["0.0.0.0/0"]
        allow = [{
          protocol = "tcp"
          ports    = ["8200"]
        }]
      },
    ]      
}

data "google_compute_subnetwork" "subnet" {
  name   = var.subnet_name
  project = var.project
  region = var.region
  depends_on = [
    module.gcp-network
  ]
}

# resource "google_compute_address" "vault-ip" {
#   name         = "vault-ip"
#   address_type = "EXTERNAL"
#   region       = var.region

#   depends_on = [ 
#     google_project_service.gcp_services ]
# }