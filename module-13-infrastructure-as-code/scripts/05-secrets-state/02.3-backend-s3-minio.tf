# =============================================================================
# Module 13 — Infrastructure as Code
# Section 13.2.3 — État (state) et backends
# Fichier : backend S3 compatible MinIO (on-premise)
# Licence : CC BY 4.0
# =============================================================================
# Backend S3 pointant vers une instance MinIO on-premise. Évite la
# dépendance à AWS DynamoDB grâce à `use_lockfile = true`.
#
# Les credentials NE DOIVENT PAS être versionnés. Préférer :
#   - variables d'environnement AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY
#   - terraform init -backend-config=backend.hcl
# =============================================================================

terraform {
  backend "s3" {
    bucket = "terraform-state"
    key    = "infrastructure/lab/terraform.tfstate"

    endpoints = {
      s3 = "https://minio.example.com:9000"
    }

    region                      = "main"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    use_path_style              = true

    # Valeurs d'exemple — à fournir via AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY
    # ou via `terraform init -backend-config=...` ; les blocs backend
    # n'acceptent pas les variables `var.*`.
    access_key = "minio-access-key"
    secret_key = "minio-secret-key"

    skip_region_validation = true

    # Verrouillage natif via un fichier de lock dans le bucket (Terraform 1.10+)
    use_lockfile = true
  }
}
