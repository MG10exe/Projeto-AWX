data "google_secret_manager_secret_version" "chave_publica" {
  secret  = "chave-publica-awxServer"
  project = var.gcp_project
}