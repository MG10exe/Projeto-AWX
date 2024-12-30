terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.12.0"
    }
  }
  backend "gcs" {}
}

provider "google" {
  credentials = var.gcp_credentials_path
  project = var.gcp_project
  region  = var.region
}

module "network" {
    source = "./modules/network"
    region = var.region
    vpc_cidr_block = var.vpc_cidr_block
    public_subnet_cidr_blocks = var.public_subnet_cidr_blocks
    private_subnet_cidr_blocks = var.private_subnet_cidr_blocks
}

module "database" {
    source = "./modules/database"
    region = var.region
    db_settings = var.db_settings
}

module "compute" {
    source = "./modules/compute"
    region = var.region
    compute_settings = var.compute_settings
    private_subnets_ids = module.network.private_subnets_ids
    public_subnets_ids = module.network.public_subnets_ids
    vpc_id = module.network.vpc_id
    my_ip = var.my_ip
    vpc_cidr_block = module.network.vpc_cidr_block
    ssh_public_key = data.google_secret_manager_secret_version.chave_publica.secret_data
}
