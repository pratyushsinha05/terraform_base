variable "service_configs" {
  type = list(object({
    name         = string
    repo_name    = string
    branch       = string
    ecr_repo_url = string
  }))
}
variable "artifact_bucket"       { type = string }
variable "codepipeline_role_arn" { type = string }
variable "codebuild_role_arn"    { type = string }
variable "region"               { type = string }

