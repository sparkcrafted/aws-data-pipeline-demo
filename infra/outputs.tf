output "landing_bucket" { value = aws_s3_bucket.landing.bucket }
output "clean_bucket" { value = aws_s3_bucket.clean.bucket }
output "curated_bucket" { value = aws_s3_bucket.curated.bucket }
output "glue_database" { value = aws_glue_catalog_database.lake.name }
output "landing_bucket_arn" { value = aws_s3_bucket.landing.arn }
output "clean_bucket_arn" { value = aws_s3_bucket.clean.arn }
