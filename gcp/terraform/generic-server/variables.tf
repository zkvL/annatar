variable "credentials_file" {}
variable "project" {}
variable "instance_name" {}
variable "hostname" {}
variable "username" {}

variable "open_ports" {
  type = list(string)
  default = ["22","80"]
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