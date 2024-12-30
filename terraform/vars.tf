variable "gcp_credentials_path" {
   type = string 
}

variable "gcp_project" {
   type = string 
}

variable "gcp_region" {
  description = "Região do GCP para criar os recursos"
  default     = "us-central1"
}

variable "vpc_cidr_block" {
  description = "CIDR block para a rede VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_count" {
  description = "Número de subnets públicas e privadas"
  type        = map(number)
  default = {
    public  = 1
    private = 2
  }
}

variable "settings" {
  description = "Configurações do Compute Engine e Cloud SQL"
  type        = map(any)
  default = {
    "database" = {
      tier                 = "db-f1-micro"  # Tipo do Cloud SQL
      database_version     = "MYSQL_8_0"   # Versão do MySQL
      instance_name        = "tutorial-db" # Nome do banco
      storage_gb           = 10            # Armazenamento
      backup_configuration = false         # Backup desativado
    },
    "web_app" = {
      count         = 1                  # Número de VMs
      machine_type  = "f1-micro"         # Tipo da máquina VM
      disk_size_gb  = 10                 # Armazenamento da VM
      image_project = "ubuntu-os-cloud"  # Projeto para a imagem
      image_family  = "ubuntu-2004-lts"  # Imagem da VM
    }
  }
}

variable "public_subnet_cidr_blocks" {
  description = "Blocos CIDR para subnets públicas"
  type        = list(string)
  default = ["10.0.1.0/24"]
}

variable "private_subnet_cidr_blocks" {
  description = "Blocos CIDR para subnets privadas"
  type        = list(string)
  default = ["10.0.2.0/24", "10.0.3.0/24"]
}

variable "my_ip" {
  description = "Seu endereço IP"
  type        = string
  default   = "34.135.151.126" 
}

variable "db_username" {
  description = "Usuário principal do banco"
  type        = string
  default     = "teste"
}

variable "db_password" {
  description = "Senha do banco de dados"
  type        = string
  default     = "ifpb"
}
