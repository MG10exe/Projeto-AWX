variable "region" {
    type = string
}
variable "compute_settings" {
    type = object({
        machine_type = string
        source_image_family = string
        source_image_project = string
        count = number
    })
}
variable "public_subnets_ids" {
    type = list(string)
}
variable "private_subnets_ids" {
    description = "IDs das sub-redes privadas"
    type        = list(string)
}
variable "vpc_id" {
    type = string
}
variable "my_ip" {
    type = string
}

variable "vpc_cidr_block" {
    type = string
}

variable "ssh_public_key" {
  description = "Chave pública SSH para acesso às instâncias"
  type        = string
}
