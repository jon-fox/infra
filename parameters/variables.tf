######## AWS ########
variable "aws_account" {
  description = "AWS account ID"
}

variable "aws_region" {
  description = "AWS region"
}

######## OPEN AI ########
variable "openai_api_key" {
  description = "OpenAI API key"
}

######## TADDY ########
variable "taddy_user_id" {
  description = "Taddy user ID"
}

variable "taddy_api_key" {
  description = "Taddy API key"
}

######## CLOUDFLARE ########
variable "cloudflare_api_token" {
  description = "Cloudflare API token"
}

######## POSTGRES ########
variable "postgres_ip" {
  description = "Postgres IP"
}

variable "postgres_auth" {
  description = "Postgres user auth"
}

######## BACKBLAZE ########
variable "backblaze_key_name" {
  description = "Backblaze key name"
}

variable "backblaze_key_id" {
  description = "Backblaze key ID"
}

variable "backblaze_api_key" {
  description = "Backblaze API key"
}

variable "backblaze_bucket_name" {
  description = "Backblaze bucket name"
}

variable "backblaze_endpoint" {
  description = "Backblaze endpoint"
}

variable "backblaze_region" {
  description = "Backblaze region"
}

variable "backblaze_cdn_url" {
  description = "Backblaze CDN URL"
}

