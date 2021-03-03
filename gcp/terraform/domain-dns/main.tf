# Terraform scripts - red team infrastructure
# author: Yael | @zkvL7
#
# annatar v1.0
#

# Connection to GCP
provider "google" {
  credentials = file(var.credentials_file)
  project = var.project
  region  = var.region
  zone    = var.zone
}

# DNS configuration - create dns managed zone
resource "google_dns_managed_zone" "default" {
  name = "${var.zone_name}"
  dns_name = "${var.domain}."
  description = "${var.domain} DNS zone"
  labels = {
    foo = "bar"
  }
}

# DNS configuration - add a record
resource "google_dns_record_set" "a-record" {
  name = "${google_dns_managed_zone.default.dns_name}"
  managed_zone = "${google_dns_managed_zone.default.name}"
  type = "A"
  ttl  = 300

  rrdatas = ["${var.instance_eip}"]
}

# DNS configuration - add mx record
resource "google_dns_record_set" "mx-record" {
  name = "${google_dns_managed_zone.default.dns_name}"
  managed_zone = "${google_dns_managed_zone.default.name}"
  type = "MX"
  ttl  = 3600
  
  rrdatas = ["1 mail.${var.domain}."]
}

# DNS configuration - add the a record for the mail server
resource "google_dns_record_set" "mx-a-record" {
  name = "mail.${google_dns_managed_zone.default.dns_name}"
  managed_zone = "${google_dns_managed_zone.default.name}"
  type = "A"
  ttl  = 300

  rrdatas = ["${var.instance_eip}"]
}

# DNS configuration - add dmarc record
resource "google_dns_record_set" "dmarc-record" {
  name = "_dmarc.${google_dns_managed_zone.default.dns_name}"
  managed_zone = "${google_dns_managed_zone.default.name}"
  type = "TXT"
  ttl  = 3600
  
  rrdatas = ["\"v=DMARC1; p=none; pct=100\""]
}

# DNS configuration - add spf record
resource "google_dns_record_set" "spf-record" {
  name = "${google_dns_managed_zone.default.dns_name}"
  managed_zone = "${google_dns_managed_zone.default.name}"
  type = "TXT"
  ttl  = 300
  
  rrdatas = ["\"v=spf1 a mx ip4:${var.instance_eip} ~all\""]
}

# DNS configuration - configure rDNS record (domain ownership confirmation is needed)
# resource "dns_ptr_record" "dns-sd" {
#   zone = "morgoth.xyz."
#   name = "r._dns-sd"
#   ptr  = var.domain
#   ttl  = 300
# }

# DNS servers for domain
output "name-servers" {
  value = "${google_dns_managed_zone.default.name_servers}"
}