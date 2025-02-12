# Terraform AWS Infrastructure

## 🚀 Overview

This project provisions an AWS infrastructure using Terraform. It sets up a Virtual Private Cloud (VPC) with an internet gateway, subnet, security group, and an Ubuntu-based web server with Apache installed.

## 📌 Features

- **VPC Creation**: A custom VPC with a public subnet.
- **Internet Gateway**: Allows external access.
- **Security Groups**: Restricts inbound traffic (SSH, HTTP, HTTPS).
- **EC2 Instance**: An Ubuntu-based web server with Apache HTTP Server installed.
- **S3 Backend Support**: Stores Terraform state securely.
- **DynamoDB Locking**: Prevents simultaneous Terraform runs.

## 📁 Project Structure

```
📦 terraform-aws-project
├── main.tf         # Main Terraform configuration
├── variables.tf    # Variables for customization
├── README.md       # Project documentation
```

## 🛠 Prerequisites

Ensure you have the following installed:

- [Terraform](https://developer.hashicorp.com/terraform/downloads)
- [AWS CLI](https://aws.amazon.com/cli/)
- AWS IAM credentials configured (`~/.aws/credentials` or environment variables)

## ⚙️ Setup & Deployment

### 1️⃣ **Initialize Terraform**

```sh
terraform init
```

### 2️⃣ **Validate the configuration**

```sh
terraform validate
```

### 3️⃣ **Plan the deployment**

```sh
terraform plan
```

### 4️⃣ **Apply the changes**

```sh
terraform apply -auto-approve
```

### 5️⃣ **Destroy resources (if needed)**

```sh
terraform destroy -auto-approve
```

## 🔐 Security Considerations

- **Do NOT hardcode AWS credentials**; use environment variables or an IAM role.
- **Restrict SSH access** to your IP instead of `0.0.0.0/0`.
- **Enable Terraform remote backend** (S3 + DynamoDB) for state management.

## 📜 License

This project is licensed under the MIT License.

---

🚀 Happy Terraforming! 🎯
