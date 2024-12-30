variable "region" {
    type = string
}
variable "db_settings" {
    type = object({
    tier            = string
    engine          = string
    engine_version  = string
    database_name   = string
    root_username   = string
    root_password   = string
    deletion_protection = bool
  })
}