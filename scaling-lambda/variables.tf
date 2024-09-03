# Variables and Provider
variable "region" {
  default = "us-east-1"
}

# terraform apply -var="phone_number=+1234567890"
variable "phone_number" {
  description = "Phone number to receive SMS messages"
}
