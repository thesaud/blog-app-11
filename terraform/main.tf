provider "aws" {
  region = var.region
}

# Generate a random string to ensure globally unique bucket names
resource "random_string" "random" {
  length  = 8
  special = false
  upper   = false
}

# Define bucket names with random suffix to ensure uniqueness
locals {
  frontend_bucket_name = "${var.frontend_bucket_name}-${random_string.random.result}"
  media_bucket_name    = "${var.media_bucket_name}-${random_string.random.result}"
}

# S3 Bucket for Frontend (Static Website Hosting)
resource "aws_s3_bucket" "frontend_bucket" {
  bucket = local.frontend_bucket_name
  force_destroy = true  # Allow Terraform to delete the bucket even if it contains objects
}

resource "aws_s3_bucket_website_configuration" "frontend_website" {
  bucket = aws_s3_bucket.frontend_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend_public_access" {
  bucket = aws_s3_bucket.frontend_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "frontend_public_read" {
  bucket = aws_s3_bucket.frontend_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend_bucket.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.frontend_public_access]
}

# S3 Bucket for Media Storage
resource "aws_s3_bucket" "media_bucket" {
  bucket = local.media_bucket_name
  force_destroy = true  # Allow Terraform to delete the bucket even if it contains objects
}

resource "aws_s3_bucket_cors_configuration" "media_bucket_cors" {
  bucket = aws_s3_bucket.media_bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_public_access_block" "media_public_access" {
  bucket = aws_s3_bucket.media_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "media_public_read" {
  bucket = aws_s3_bucket.media_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.media_bucket.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.media_public_access]
}

# IAM User for S3 Access (for Media Uploads and Frontend Deployment)
resource "aws_iam_user" "s3_user" {
  name = "blog-app-s3-user"
}

resource "aws_iam_access_key" "s3_user_key" {
  user = aws_iam_user.s3_user.name
}

resource "aws_iam_user_policy" "s3_user_policy" {
  name = "s3_access_policy"
  user = aws_iam_user.s3_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.media_bucket.arn}/*"
      },
      {
        Action = [
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = aws_s3_bucket.media_bucket.arn
      },
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = [
          aws_s3_bucket.frontend_bucket.arn,
          "${aws_s3_bucket.frontend_bucket.arn}/*"
        ]
      }
    ]
  })
}

# Security Group for Backend EC2 Instance
resource "aws_security_group" "backend_sg" {
  name        = "backend-security-group"
  description = "Security group for backend EC2 instance"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Backend app port"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
}

# EC2 Launch Template
resource "aws_launch_template" "backend_template" {
  name                   = "backend-launch-template"
  image_id               = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.backend_sg.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash

    # Set up logging to make debugging easier
    exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

    echo "Starting EC2 initialization script..."

    # System Updates and Essential Packages
    echo "Updating system packages..."
    apt update -y
    apt install -y git curl unzip tar gcc g++ make

    # Node.js Installation via NVM
    echo "Installing Node.js via NVM..."
    su - ubuntu -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash'

    # Install the latest LTS version of Node.js
    su - ubuntu -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && nvm install --lts'

    # Set the installed version as the default
    su - ubuntu -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && nvm alias default node'

    # PM2 Installation and Configuration
    echo "Installing PM2 globally..."
    su - ubuntu -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && npm install -g pm2'

    # Configure PM2 to start on system boot
    echo "Configuring PM2 startup..."
    su - ubuntu -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && pm2 startup'

    # Generate and run the startup script with proper permissions
    env PATH=$PATH:/home/ubuntu/.nvm/versions/node/$(su - ubuntu -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && node -v')/bin /home/ubuntu/.nvm/versions/node/$(su - ubuntu -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && node -v')/lib/node_modules/pm2/bin/pm2 startup systemd -u ubuntu --hp /home/ubuntu

    # Create logs directory for the application
    echo "Creating logs directory..."
    su - ubuntu -c 'mkdir -p ~/logs'

    # AWS CLI Installation
    echo "Installing AWS CLI..."
    apt install -y awscli

    echo "EC2 initialization script completed!"
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "backend-blog-app"
    }
  }
}

# EC2 Instance
resource "aws_instance" "backend_instance" {
  launch_template {
    id      = aws_launch_template.backend_template.id
    version = "$Latest"
  }

  tags = {
    Name = "blog-app-backend"
  }
} 