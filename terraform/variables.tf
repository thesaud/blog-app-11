variable "region" {
  description = "AWS region to deploy resources"
  default     = "eu-north-1"
}

variable "frontend_bucket_name" {
  description = "Name of S3 bucket for frontend static website hosting"
  default     = "blog-app-1003-frontend-bucket"
}

variable "media_bucket_name" {
  description = "Name of S3 bucket for media storage"
  default     = "blog-app-1003-media-bucket"
}

variable "ami_id" {
  description = "AMI ID for EC2 instance (Ubuntu 22.04)"
  default     = "ami-0989fb15ce71ba39e" # Ubuntu 22.04 LTS in eu-north-1
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.medium"
}

variable "key_name" {
  description = "SSH key pair name"
  default     = "wind" # Replace with your key pair name
} 

variable "mongodb_connection_string" {
  description = "MongoDB Atlas connection string"
  type        = string
  sensitive   = true
  default     = "mongodb+srv://@@@@@@@@@@@cluster0.w8qrr21.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0"
}