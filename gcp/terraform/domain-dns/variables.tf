variable "credentials_file" {}
variable "project" {}
variable "instance_eip" {}
variable "domain" {}

variable "zone_name" {
  type = string
  default = "annatar-dns-zone"
}

variable "ssh_pubKey" {
  type = string
  default = "~/.ssh/id_rsa.pub"
}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-c"
}