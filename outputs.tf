output "service_alb_dns" {
  description = "DNS names of service ALBs"
  value       = { for name, svc in module.service : name => svc.alb_dns }
}

output "ecr_repo_url" {
  description = "URLs of ECR repositories"
  value       = { for name, repo in module.ecr : name => repo.repository_url }
}

# output "pipeline_names" {
#   description = "Names of CodePipeline pipelines"
#   value       = { for name, p in module.cicd.pipeline : name => p.name }
# }

