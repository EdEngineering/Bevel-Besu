# # ----------------- Vault GKE approach -----------------

resource "kubernetes_namespace" "vault" {
  metadata {
    name = "vault"
  }
}

resource "kubernetes_namespace" "consul" {
  metadata {
    name = "consul"
  }
}

resource "helm_release" "consul" {
  name       = "consul"
  chart      = "consul"
  repository = "https://helm.releases.hashicorp.com"
  namespace  = kubernetes_namespace.consul.metadata[0].name

  values = [
    templatefile("/home/eduser/Repos/Ansible-Bevel-Test/environments/test/tf-helm/consul/consul.yaml", { replicas =  2 }),
  ] 
}   

resource "helm_release" "vault" {
  depends_on = [ helm_release.consul ]

  name = "vault"
  repository = "https://helm.releases.hashicorp.com"
  chart = "vault"
  version = "0.24.1"
  namespace = kubernetes_namespace.vault.metadata[0].name

  values = [ 
    templatefile("/home/eduser/Repos/Ansible-Bevel-Test/environments/test/tf-helm/vault/vault.yaml", { replicas =  1 })
   ]
}

data "kubernetes_service" "vault_svc" {
  depends_on = [ 
    helm_release.vault
   ]

   metadata {
    name = "vault"
    namespace = kubernetes_namespace.vault.metadata[0].name
   }
}

# #Enough for deploying a vault instance in GCE --------------------- GCE Approach
# module "vault" {
#   source         = "terraform-google-modules/vault/google"
#   project_id     = var.project
#   region         = var.region
#   kms_keyring    = var.kms_keyring
#   kms_crypto_key = var.kms_crypto_key

#   vault_machine_type = "e2-medium"
#   domain = "net-vault.evasquezapplaudo.ga"

#   depends_on = [ 
#     google_project_service.gcp_services
#    ]
# }

# # ----------------- Vault VM other approach -----------------

# resource "google_compute_instance" "vault-vm" {
#   machine_type = "e2-small"
#   name         = "vault-vm"
#   zone = var.zone

#   metadata_startup_script = <<-SCRIPT
#     #!/bin/bash
    
#     # Update the system
#     apt-get update
    
#     # Install Vault CLI
#     curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
#     sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
#     sudo apt-get update && sudo apt-get install vault
    
#     # Install Apache
#     apt-get install -y apache2
    
#     # Start Apache service
#     systemctl start apache2
    
#     sudo systemctl enable apache2


#   SCRIPT
#   boot_disk {
#     auto_delete = true
#     device_name = "vault-vm"

#     initialize_params {
#       image = "projects/ubuntu-os-cloud/global/images/ubuntu-2204-jammy-v20230606"
#       size  = 10
#       type  = "pd-balanced"
#     }

#     mode = "READ_WRITE"
#   }

#   tags = ["http-server", "https-server", "allow-vault"]
#   labels = {
#     goog-ec-src = "vm_add-tf"
#   }


#   network_interface {
#     access_config {
#       network_tier = "PREMIUM"
#     }
#     subnetwork = "projects/${var.project}/regions/${var.region}/subnetworks/default"

#   }
# }
