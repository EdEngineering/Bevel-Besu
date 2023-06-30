resource "google_dns_managed_zone" "net_zone" {
  name        = "net-zone"
  dns_name    = var.dns_name
  description = "DNS zone for fabric network endpoints"
  depends_on = [
    google_project_service.gcp_services
  ]
}


# resource "google_dns_record_set" "ca_ord_record" {
#   name    = "net-ord-ca.${var.dns_name}"
#   type    = "A"
#   ttl     = 300
#   managed_zone = google_dns_managed_zone.net_zone.name
#   rrdatas = [
#     google_compute_address.vault-ip.address
#   ]
# }

# resource "google_dns_record_set" "nodes_ord_record" {
#   count   = 3
#   name    = "net-ord-node${count.index}.${var.dns_name}"
#   type    = "A"
#   ttl     = 300
#   managed_zone = google_dns_managed_zone.net_zone.name
#   rrdatas = [
#     google_compute_address.vault-ip.address
#   ]
# }


# resource "google_dns_record_set" "ca_org_record" {
#   for_each = var.org_records
#   name = "net-${each.value}-ca.${var.dns_name}"
#   type    = "A"
#   ttl     = 300
#   managed_zone = google_dns_managed_zone.net_zone.name
#   rrdatas = [
#     google_compute_address.vault-ip.address
#   ]
# }

# resource "google_dns_record_set" "peer0_org_record" {
#   for_each = var.org_records
#   name = "net-${each.value}-peer0.${var.dns_name}"
#   type    = "A"
#   ttl     = 300
#   managed_zone = google_dns_managed_zone.net_zone.name
#   rrdatas = [
#     google_compute_address.vault-ip.address
#   ]
# }



## ------------------ Vault DNS Record GCE Approach------------------ ##
# resource "google_dns_record_set" "vault_record" {
#   name = "net-vault.${var.dns_name}"
#   type    = "A"
#   ttl     = 300
#   managed_zone = google_dns_managed_zone.net_zone.name
#   rrdatas = [
#     module.vault.vault_lb_addr
#   ]
# }
