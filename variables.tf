variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to the SSH private key"
  type        = string
}

variable "droplet_image" {
  description = "Droplet image to use (e.g., 'ubuntu-20-04-x64')"
}

variable "droplet_name" {
  description = "Name of the Droplet"
  type        = string
}

variable "droplet_region" {
  description = "Region for the Droplet (e.g., 'nyc1')"
  type        = string
}

variable "droplet_size" {
  description = "Size of the Droplet (e.g., 's-1vcpu-1gb')"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository URL"
}

variable "node_version" {
  description = "Node.js version to install"
}

variable "domain_name" {
  description = "Domain name for Nginx configuration"
}

variable "aws_access_key" {
  description = "Access Key for AWS"
  type        = string
}

variable "aws_secret_key" {
  description = "Secret Key for AWS"
  type        = string
}

variable "secret_name" {
  description = "secret for env"
  type        = string
}

variable "aws_region" {
  description = "AWS Region"
}