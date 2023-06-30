resource "google_project_service" "gcp_services" {
  for_each                   = toset(var.gcp_service_list)
  project                    = var.project
  service                    = each.key
  disable_dependent_services = true
}

module "gke" {
  source                 = "terraform-google-modules/kubernetes-engine/google"
  project_id             = var.project
  name                   = var.name
  regional               = false
  zones                  = var.cluster_node_zones
  network                = module.gcp-network.network_name
  subnetwork             = module.gcp-network.subnets_names[0]
  ip_range_pods          = var.ip_range_pods_name
  ip_range_services      = var.ip_range_services_name
  create_service_account = true
  remove_default_node_pool = true

  depends_on = [ 
    module.gcp-network ]

  node_pools = [
    {
      name               = "node-pool-01"
      machine_type       = "n1-standard-4"
      node_locations     = var.zone
      disk_size_gb       = 100
      disk_type          = "pd-standard"
      image_type         = "COS_CONTAINERD"
      auto_repair        = true
      auto_upgrade       = true
      autoscaling        = false
      node_count         = 4
      # preemptible        = true
    },
  ]
  node_pools_oauth_scopes = {
    node_pool-01 = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/trace.append",
      "https://www.googleapis.com/auth/ndev.clouddns.readwrite"
    ]
  }
  node_pools_labels = {
    node_pool-01 = {
      "node-pool" = "node-pool-01"
    }
  }
}




# resource "google_compute_router" "router" {
#   project = var.project
#   name    = "${module.gcp-network.network_name}-nat-router"
#   network = module.gcp-network.network_name
#   region  = var.region
# }

# module "cloud-nat" {
#   source                             = "terraform-google-modules/cloud-nat/google"
#   version                            = "~> 2.0"
#   project_id                         = var.project
#   region                             = var.region
#   router                             = google_compute_router.router.name
#   name                               = "${module.gcp-network.network_name}-nat-config"
#   source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
# }



# resource "google_compute_address" "lb_ip" {
#   name         = "lb-${var.name}"
#   address_type = "EXTERNAL"
#   region       = var.region

#   depends_on = [ 
#     google_project_service.gcp_services ]
# }

# resource "null_resource" "lb_ip_istio" {
#   provisioner "local-exec" {
#     command = "ip=${google_compute_address.lb_ip.address} yq e -i '.spec.components.ingressGateways[0].k8s.service.loadBalancerIP = env(ip)' ../../manifests/istio-gateway.yaml"
#   }
#   depends_on = [
#     google_compute_address.lb_ip
#   ]
# }





# resource "google_service_account" "node_sa" {
#   account_id   = "node-sa-${var.name}"
#   display_name = "Service Account for node pool"
# }

# module "google_networks" {
#   source = "../../modules/network"

#   network_name = "${var.name}-net"
#   project_id   = var.project
#   region       = var.region
# }

# module "google_kubernetes_cluster" {
#   source                     = "../../modules/kubernetes_cluster"
#   cluster_name               = var.name
#   project_id                 = var.project
#   region                     = var.region
#   node_zones                 = var.cluster_node_zones
#   disk_size_gb               = 30
#   preemptible                = true
#   service_account            = google_service_account.node_sa.email
#   network_name               = module.google_networks.network.name
#   subnet_name                = module.google_networks.subnet.name
#   master_ipv4_cidr_block     = module.google_networks.cluster_master_ip_cidr_range
#   pods_ipv4_cidr_block       = module.google_networks.cluster_pods_ip_cidr_range
#   services_ipv4_cidr_block   = module.google_networks.cluster_services_ip_cidr_range
#   authorized_ipv4_cidr_block = "190.62.18.60/32"
#   node_count                 = 3
# }


