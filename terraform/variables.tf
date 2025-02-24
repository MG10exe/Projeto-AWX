variable "gcp_credentials_path" {
  type = string
}

variable "gcp_project" {
  type = string
}

variable "region" {
  description = "Região do GCP"
  type        = string
  default     = "us-central1"
}

variable "public_subnet_cidr_blocks" {
  description = "CIDR blocks para sub-redes públicas"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "private_subnet_cidr_blocks" {
  description = "CIDR blocks para sub-redes privadas"
  type        = list(string)
  default     = ["10.0.101.0/24"]
}

variable "db_settings" {
  type = object({
    tier               = string
    engine_version     = string
    database_name      = string
    root_username      = string
    root_password      = string
    deletion_protection = bool
  })
  default = {
    tier               = "db-f1-micro"
    engine_version     = "MYSQL_8_0"
    database_name      = "ifpb"
    root_username      = "admin"
    deletion_protection = false
  }
}

variable "compute_settings" {
  type = object({
    machine_type        = string
    source_image_family = string
    source_image_project = string
    count              = number
  })
  default = {
    machine_type        = "e2-micro"
    source_image_family = "ubuntu-2004-lts"
    source_image_project = "ubuntu-os-cloud"
    count              = 1
  }
}

variable "my_ip" {
  description = "Seu endereço IP para acesso SSH"
  type        = string
  default     = "34.55.100.16"
}
