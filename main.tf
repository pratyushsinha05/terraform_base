data "aws_caller_identity" "current" {}

data "aws_ssm_parameter" "amzn2_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

module "networking" {
  source               = "./modules/core/networking"
  project_name         = var.project_name
  vpc_cidr             = "10.0.0.0/16"
  azs                  = ["${var.region}a", "${var.region}b", "${var.region}c"]
  public_subnet_cidrs  = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

module "iam" {
  source         = "./modules/core/iam"
  project_name   = var.project_name
  create_kms_key = true
}

module "s3_static" {
  source      = "./modules/storage/s3-static"
  bucket_name = "${var.project_name}-artifacts"
  kms_key_id  = module.iam.kms_key_id
}

module "ecr" {
  for_each  = { for svc in var.services : svc.name => svc }
  source    = "./modules/storage/ecr"
  repo_name = each.value.repo_name
}

module "service" {
  for_each        = { for svc in var.services : svc.name => svc }
  source          = "./modules/services/service"

  service_name    = each.key
  vpc_id          = module.networking.vpc_id
  public_subnets  = module.networking.public_subnets
  private_subnets = module.networking.private_subnets
  alb_sg_id       = module.networking.alb_sg_id

  # Attach the EC2 instance profile from the IAM module
  instance_profile = module.iam.ec2_instance_profile

  # AMI, sizing, and scaling
  instance_ami     = data.aws_ssm_parameter.amzn2_ami.value
  instance_type    = "t3.micro"
  desired_capacity = 2
  max_size         = 5

  # Application port & Docker image
  app_port         = each.value.app_port
  docker_image_url = module.ecr[each.key].repository_url
}



# module "cicd" {
#   source                = "./modules/ci-cd"
#   service_configs       = [ for svc in var.services : {
#     name         = svc.name
#     repo_name    = svc.repo_name
#     branch       = svc.branch
#     ecr_repo_url = module.ecr[svc.name].repository_url
#   }]
#   artifact_bucket       = module.s3_static.bucket_id
#   codepipeline_role_arn = module.iam.codepipeline_role_arn
#   codebuild_role_arn    = module.iam.codebuild_role_arn
#   region                = var.region
# }