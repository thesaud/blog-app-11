# 🛠️ MERN Stack Blog App Deployment using Terraform & Ansible -SDA1003

This project demonstrates how to **provision and deploy a MERN stack blog application** on AWS using **Terraform** for infrastructure and **Ansible** for backend server automation.

---

## 📌 Tech Stack

- **Terraform** – Infrastructure as Code (IaC)
- **Ansible** – Configuration Management
- **AWS EC2** – Backend hosting
- **S3 (Static Site Hosting)** – Frontend deployment
- **S3 (Media)** – Media uploads
- **MongoDB Atlas** – Database

---

## 🗺️ Architecture Diagram

```
                     ┌───────────────┐
                     │   Route 53    │
                     │  (Optional)   │
                     └──────┬────────┘
                            │
            ┌───────────────┼────────────────┐
            │               │                │
      ┌─────▼──────┐  ┌─────▼──────┐   ┌─────▼──────┐
      │ Frontend   │  │   EC2      │   │  Media     │
      │  S3 Bucket │  │ (Backend)  │   │  S3 Bucket │
      └────────────┘  └─────┬──────┘   └────────────┘
                            │
                            ▼
                    ┌──────────────┐
                    │ MongoDB Atlas│
                    └──────────────┘
```

---

## ⚙️ Prerequisites

- AWS account with CLI configured
- SSH key pair (for EC2 access)
- Terraform CLI
- Ansible
- MongoDB Atlas account

---

## 🚀 Deployment Steps

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/mern-blog-deploy.git
cd mern-blog-deploy
```

### 2. Infrastructure with Terraform

```bash
cd terraform
terraform init
terraform apply
```

- Creates EC2, S3 buckets, IAM user, and security groups.
- After apply, copy the output values (S3 credentials, IPs, etc.)

---

### 3. MongoDB Atlas Setup

- Create free-tier cluster
- Whitelist EC2 public IP
- Create user and get connection string
- Paste the string in Ansible `.env.j2` file

---

### 4. Backend Deployment with Ansible

```bash
cd ansible
ansible-playbook -i inventory backend-playbook.yml --extra-vars "@extra_vars.yml"
```

- Clones the app
- Configures environment variables
- Installs Node.js and PM2
- Starts backend

---

### 5. Frontend Build and Upload

```bash
cd ~/blog-app/frontend

# Create .env
cat > .env <<EOF
VITE_BASE_URL=http://<EC2_PUBLIC_IP>:5000/api
VITE_MEDIA_BASE_URL=https://<media-bucket-name>.s3.<region>.amazonaws.com
EOF

# Install and build
npm install -g pnpm
pnpm install
pnpm run build

# Upload to S3
aws s3 sync dist/ s3://<frontend-bucket-name>
```

---

## 📁 Project Structure

```
.
├── terraform/
│   ├── main.tf
│   ├── outputs.tf
│   └── variables.tf
├── ansible/
│   ├── inventory
│   ├── backend-playbook.yml
│   └── roles/
│       └── backend/
│           ├── tasks/
│           ├── templates/
│           └── vars/
└── README.md
```

---

## ✅ Screenshots to Include

| Screenshot                     | Description                   |
|-------------------------------|-------------------------------|
| PM2 Running                   | Backend process up & running  |
| MongoDB Atlas Cluster         | Database connection success   |
| Media Upload                  | S3 media upload functional    |
| Frontend in Browser           | Static site from S3 live      |

---

## 🧹 Cleanup

```bash
# Terraform destroy
cd terraform
terraform destroy

# Clean EC2 .env
ssh -i <your-key.pem> ubuntu@<ec2-ip>
rm ~/blog-app/backend/.env
```

- Delete Atlas user/IP if needed
- Revoke IAM credentials (media access)

---

## ⚠️ Security Tips

- Never commit `.env` files
- Do not include `AWS_SECRET_ACCESS_KEY` in your repo
- Use `.gitignore` wisely

---

## 📌 Author

Made by **Saud AlQurashi** – as part of the Clarusway Infrastructure Bootcamp (Week 11 Assignment)

---

## 📬 Contact

For questions or feedback, feel free to reach out.
