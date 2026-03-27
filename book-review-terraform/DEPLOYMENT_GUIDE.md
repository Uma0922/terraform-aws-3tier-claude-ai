Deployment Guide — Book Review App

This guide walks through deploying the Book Review App on AWS using Claude Code, Terraform, and EC2 user_data. Claude Code was used as the primary working environment throughout — for writing and editing Terraform, generating bootstrap scripts, debugging errors, and running all commands.
The deployment provisions a full three-tier architecture and automatically bootstraps both the frontend and backend on terraform apply.

🏗️ What Gets Deployed
Resource Details: VPC Public and private subnets across 2 AZs Security GroupsWeb, app, ALB, and database tiers Public ALB Internet-facing entry point on port 80Internal ALB Routes web → app tier on port 3001Web EC2Next.js + Nginx + PM2 (public subnet)App EC2Node.js/Express + PM2 (private subnet)RDS MySQLPrivate subnet, port 3306

Traffic Flow
Browser
   ↓
Public ALB (port 80)
   ↓
Web EC2 — Next.js frontend + Nginx + PM2
   ↓ /api
Internal ALB (port 3001)
   ↓
App EC2 — Node.js/Express backend + PM2
   ↓
RDS MySQL

🤖 How Claude Code Was Used
Claude Code was the primary tool for building and deploying this project — not just an assistant, but the actual working environment.
Claude Code was used to:

Open and analyze the Terraform repo structure
Write and refine user_data bootstrap scripts for both EC2 tiers
Edit main.tf, variables.tf, and all module files
Pass environment values (DB host, ALB DNS, JWT secret) into EC2 modules
Review diffs before every terraform apply
Run all Terraform commands in the Claude Code terminal
Debug cloud-init errors, PM2 failures, and Nginx misconfigurations
Explain Terraform errors in plain language and suggest fixes


Claude Code handled the editing and troubleshooting. Terraform and AWS CLI did the actual provisioning.

To replicate this workflow, open the Terraform repo in Claude Code and start with:
Analyze this Terraform repo and help me deploy the full Book Review
application on AWS using user_data for both the web and app EC2 instances.
Make sure the frontend is public through the ALB and the backend connects to RDS through the private tier.

✅ Prerequisites
Ensure the following are installed and configured:

Terraform v1.0+
AWS CLI v2
Git
Claude Code (primary working environment for this project)
AWS account with permissions for: VPC, EC2, ALB, RDS, Security Groups, Key Pairs

Configure AWS credentials in the Claude Code terminal:
bash 
aws configure

https://github.com/pravinmishraaws/book-review-app.gitApplication source (frontend + backend)

Pravin's repo is the original app source without the bootstrap scripts.


🪜 Deployment Steps

All commands below were run inside the Claude Code terminal.


Step 1 — Clone the Repositories
bash
cd ~/Desktop

# App source repo
git clone (this repo)

cd book-review-terraform-iac
Open the book-review-terraform-iac folder in Claude Code. This is where all Terraform work happens.

Step 2 — Create an EC2 Key Pair
Run this in the Claude Code terminal:
bash
aws ec2 create-key-pair \
  --region eu-north-1 \
  --key-name book-review-key \
  --query 'KeyMaterial' \
  --output text > book-review-key.pem

choose region and key name

chmod 400 book-review-key.pem

Terraform references this key pair by name to launch EC2 instances. Without it, provisioning will fail.


Step 3 — Create terraform.tfvars
Claude Code was used to create and populate this file. In the root of the Terraform repo:
hcl
aws_region        = "eu-north-1"
project           = "book-review"

# VPC & Subnets
vpc_cidr_block    = "10.0.0.0/16"
web_subnet_1_cidr = "10.0.1.0/24"
web_subnet_2_cidr = "10.0.2.0/24"
app_subnet_1_cidr = "10.0.10.0/24"
app_subnet_2_cidr = "10.0.11.0/24"
db_subnet_1_cidr  = "10.0.20.0/24"
db_subnet_2_cidr  = "10.0.21.0/24"

# EC2
keyname           = "book-review-key"
web_instance_type = "t3.micro"
app_instance_type = "t3.micro"

# RDS
allocated_storage = 20
db_name           = "book_review_db"
engine            = "mysql"
engine_version    = "8.0"
instance_class    = "db.t3.micro"
username          = "admin"
password          = "ChangeThisToAStrongPassword123!"  # ⚠️ Change this!

⚠️ Never commit terraform.tfvars to version control. It contains secrets.


Step 4 — Verify .gitignore
Claude Code was used to set up .gitignore so no secrets or state files were committed: (In case you're pushing to github)
gitignore# Terraform
.terraform/
*.tfstate
*.tfstate.*
crash.log
*.tfvars
*.tfvars.json

# Keys & Secrets
*.pem
*.key
.env
.env.*
!.env.example

# Dependencies & Logs
node_modules/
*.log

# Editor / OS
.DS_Store
Thumbs.db
.vscode/
.idea/

Step 5 — EC2 Bootstrap with user_data
Claude Code was used to write and refine the user_data scripts in scripts/ that automatically deploy both tiers on instance boot — removing the need for any manual SSH deployment after terraform apply.
App EC2 (backend-userdata.sh.tpl) does:

Installs Node.js, PM2, Git, and mysql-client
Clones the app repo
Installs backend dependencies
Writes the backend .env
Starts the backend with PM2 on port 3001

Web EC2 (frontend-userdata.sh.tpl) does:

Installs Node.js, PM2, Git, and Nginx
Clones the app repo
Installs frontend dependencies
Writes .env.local
Builds the Next.js frontend
Starts the frontend with PM2 on port 3000
Configures Nginx as a reverse proxy

Claude Code also wired up the root main.tf to pass all required values into the EC2 module so the bootstrap scripts receive the correct environment at boot:
hcl
module "ec2" {
  source = "./modules/ec2"

  # ... networking and instance config ...

  app_repo_url    = "https://github.com/pravinmishraaws/book-review-app.git"
  db_host         = split(":", module.database.db_endpoint)[0]
  db_port         = 3306
  db_name         = var.db_name
  db_user         = var.username
  db_pass         = var.password
  public_alb_dns  = module.alb.public_alb_dns_name
  private_alb_dns = module.alb.private_alb_dns_name
  jwt_secret      = "ChangeThisJWTSecretNow123!"
}

Step 6 — Initialize and Deploy
Run these commands in the Claude Code terminal:
bash
/init            # Download providers and initialize
terraform validate        # Check for syntax/configuration errors
/plan            # Preview what will be created
/apply           # Deploy (type 'yes' when prompted)

Always review terraform plan output before applying. Claude Code was used to inspect and explain the plan at this stage.

terraform apply provisions all infrastructure and triggers the user_data scripts that install and start both the frontend and backend automatically.

Step 7 — Get Outputs
bash
terraform output
OutputUsepublic_alb_dns_namePublic URL to open in browserwebserver_pub_ipSSH access to web EC2appserver_prvt_ipApp server private IPdb_endpointRDS connection endpoint

Step 8 — Wait for Bootstrap to Complete
After terraform apply, wait 3–8 minutes before opening the app.
The user_data scripts need time to complete:

Package installation
Repository cloning
Frontend build (next build)
Nginx configuration
PM2 startup


Terraform finishes before the application is fully ready — this is expected behaviour.


Step 9 — Open the App
http://<public_alb_dns_name>
A successful deployment means:

The frontend loads in the browser
/api/ requests are proxied through to the backend
The backend connects to RDS
Users can register and interact with the app


📜 Manual Redeployment (Scripts)
If you need to redeploy or update the application without re-running Terraform, use the scripts in scripts/. These were written and tested using Claude Code.
Prepare Scripts

bash
chmod +x scripts/deploy-backend.sh scripts/deploy-frontend.sh
Backend Script
Open scripts/deploy-backend.sh and update:
VariableValueDB_HOSTRDS endpoint (hostname only, no port)DB_PASSYour RDS passwordALLOWED_ORIGINSPublic ALB DNS (no http://)JWT_SECRETReplace the default
SSH into the app EC2 and run:
bashcd /path/to/book-review-terraform-iac
./scripts/deploy-backend.sh
Verify:
bashpm2 status
pm2 logs bk-backend --lines 100
Frontend Script
Open scripts/deploy-frontend.sh and update:
VariableValuePUBLIC_ALB_DNSPublic ALB DNS (no http://)INTERNAL_ALB_DNSInternal ALB DNS (no http://)
SSH into the web EC2 and run:
bashcd /path/to/book-review-terraform-iac
./scripts/deploy-frontend.sh
Verify:
bashpm2 status
sudo nginx -t
sudo systemctl status nginx --no-pager

⚙️ Environment Variable Reference
Backend .env
envPORT=3001
DB_HOST=<rds-hostname-only>
DB_PORT=3306
DB_USER=admin
DB_PASS=<your-password>
DB_NAME=book_review_db
JWT_SECRET=<your-jwt-secret>
ALLOWED_ORIGINS=http://<public-alb-dns>

Use only the hostname in DB_HOST — not hostname:3306.

Frontend .env.local
envNEXT_PUBLIC_API_URL=http://<public-alb-dns>/api

The frontend calls the backend through the public ALB /api path, not directly to the private app server.


🔍 Debugging Checklist
Claude Code was used to debug issues at each of these layers.
Web EC2
bash# PM2 processes
pm2 status
pm2 logs

# Nginx
sudo nginx -t
sudo systemctl status nginx

# Bootstrap log (check this first)
sudo cat /var/log/cloud-init-output.log
App EC2
bashpm2 status
pm2 logs
sudo cat /var/log/cloud-init-output.log
Browser
Open DevTools → Network tab and inspect failing /api/... requests for status codes and error messages.

🐛 Common Issues
Issue Cause Fix: Frontend loads but shows "No books"Backend not ready or not connected Check PM2 logs and RDS connectivity 

Permission denied on scripts Missing execute bit chmod +x scripts/*.shRDS takes a long time 

Normal — RDS is slow to provision Wait it out EC2 replaced on re-apply user_data change triggers replacement Expected Terraform behaviour CORS errors ALLOWED_ORIGINS mismatch Match the exact frontend domain DB connection refused Wrong DB_HOST or security group Use hostname only; check SG rules Nginx config fails Syntax error in generated config sudo nginx -t and inspect output Backend on wrong portApp not listening on 3001Internal ALB expects port 3001

⚡ Quick Command Reference
All commands run in the Claude Code terminal:
bash# Clone repos
cd ~/Desktop
git clone (The repo)
cd book-review-terraform-iac

# Create key pair
aws ec2 create-key-pair \
  --region eu-north-1 \
  --key-name book-review-key \
  --query 'KeyMaterial' \
  --output text > book-review-key.pem
chmod 400 book-review-key.pem

# Deploy
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply

# Get public URL
terraform output public_alb_dns_name
Then open http://<public_alb_dns_name> in your browser.

🧹 Cleanup
To destroy all provisioned AWS infrastructure:
bashterraform destroy

This prevents ongoing AWS charges when the environment is no longer needed.