output "db_address" {
    value = google_sql_database_instance.database.private_ip_address
}
output "db_port" {
    value = 3306
}