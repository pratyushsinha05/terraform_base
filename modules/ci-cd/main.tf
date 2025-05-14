resource "aws_codebuild_project" "build" {
  for_each    = { for s in var.service_configs : s.name => s }
  name        = "${each.key}-build"
  service_role= var.codebuild_role_arn
  artifacts { type = "CODEPIPELINE" }
  environment {
  compute_type    = "BUILD_GENERAL1_SMALL"
  image           = "aws/codebuild/standard:5.0"
  type            = "LINUX_CONTAINER"
  privileged_mode = true

  environment_variable {
    name  = "ECR_REPO_URI"
    value = each.value.ecr_repo_url
  }
  environment_variable {
    name  = "AWS_DEFAULT_REGION"
    value = var.region
  }
}

  source { type = "CODEPIPELINE" }
  cache { type = "LOCAL" }
}

resource "aws_codepipeline" "pipeline" {
  for_each = { for s in var.service_configs : s.name => s }
  name     = "${each.key}-pipeline"
  role_arn = var.codepipeline_role_arn
  artifact_store {
    type     = "S3"
    location = var.artifact_bucket
    encryption_key {
      id   = var.artifact_bucket
      type = "KMS"
   }
  }
  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["${each.key}-src"]
      configuration = {
        RepositoryName = each.value.repo_name
        BranchName     = each.value.branch
      }
    }
  }
  stage {
    name = "Build"
    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["${each.key}-src"]
      configuration = {
        ProjectName = aws_codebuild_project.build[each.key].name
      }
    }
  }
}

