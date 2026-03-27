terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "./modules/networking"

  project           = var.project
  vpc_cidr_block    = var.vpc_cidr_block
  web_subnet_1_cidr = var.web_subnet_1_cidr
  web_subnet_2_cidr = var.web_subnet_2_cidr
  app_subnet_1_cidr = var.app_subnet_1_cidr
  app_subnet_2_cidr = var.app_subnet_2_cidr
  db_subnet_1_cidr  = var.db_subnet_1_cidr
  db_subnet_2_cidr  = var.db_subnet_2_cidr
}

module "security" {
  source = "./modules/security"

  book_review_vpc_id = module.vpc.book_review_vpc_id
  project            = var.project
  vpc_cidr_block     = var.vpc_cidr_block
}

module "ec2" {
  source = "./modules/ec2"

  project           = var.project
  web_sg_id         = module.security.web_sg_id
  app_sg_id         = module.security.app_sg_id
  keyname           = var.keyname
  web_instance_type = var.web_instance_type
  app_instance_type = var.app_instance_type
  app_subnet_1_id   = module.vpc.app_subnet_1_id
  app_subnet_2_id   = module.vpc.app_subnet_2_id
  web_subnet_1_id   = module.vpc.web_subnet_1_id
  web_subnet_2_id   = module.vpc.web_subnet_2_id

  web_user_data = templatefile("${path.root}/scripts/frontend-userdata.sh.tpl", {
    public_alb_dns  = module.alb.public_alb_dns_name
    private_alb_dns = module.alb.private_alb_dns_name
  })

  app_user_data = templatefile("${path.root}/scripts/backend-userdata.sh.tpl", {
    db_host        = split(":", module.database.db_endpoint)[0]
    db_user        = var.username
    db_pass        = var.password
    db_name        = var.db_name
    public_alb_dns = module.alb.public_alb_dns_name
  })
}

module "database" {
  source            = "./modules/database"
  project           = var.project
  allocated_storage = var.allocated_storage
  db_name           = var.db_name
  engine            = var.engine
  engine_version    = var.engine_version
  instance_class    = var.instance_class
  username          = var.username
  password          = var.password
  db_subnet_1_id    = module.vpc.db_subnet_1_id
  db_sg_id          = module.security.db_sg_id
  db_subnet_2_id    = module.vpc.db_subnet_2_id
}

module "alb" {
  source = "./modules/alb"

  project                = var.project
  vpc_id                 = module.vpc.vpc_id
  web_subnet_1_id        = module.vpc.web_subnet_1_id
  web_subnet_2_id        = module.vpc.web_subnet_2_id
  app_subnet_1_id        = module.vpc.app_subnet_1_id
  app_subnet_2_id        = module.vpc.app_subnet_2_id
  internal_alb_sg_id     = module.security.internal_alb_sg_id
  pub_alb_sg_id          = module.security.pub_alb_sg_id
  web_server_instance_id = module.ec2.web_server_instance_id
  app_server_instance_id = module.ec2.app_server_instance_id
}