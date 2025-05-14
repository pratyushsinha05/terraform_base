output "kms_key_id"             { value = length(aws_kms_key.main) > 0 ? aws_kms_key.main[0].id : null }
output "ec2_instance_profile"  { value = aws_iam_instance_profile.ec2.name }
output "codebuild_role_arn"    { value = aws_iam_role.codebuild.arn }
output "codepipeline_role_arn" { value = aws_iam_role.codepipeline.arn }



