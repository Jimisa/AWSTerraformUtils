output "efs_id" {
    description = "The ID of the created EFS"
    value       = aws_efs_file_system.this.id
}

output "security_group_id" {
    description = "the ID of the security group of the EFS"
    value       = aws_security_group.for_efs.id
}

output "path_access_point_ids" {
    description = "an list of objects with the ID and the directory path of thee access point resource created for the EFS"
    value       = [for efs in aws_efs_access_point.this:
                    zipmap(["id","path"],[efs.id,efs.tags_all.path])
                ]
}

# output "access_point_arn" {
#     description = "The ARN of the access point ressource created for the EFS"
#     value       = aws_efs_access_point.this[*].arn
#}

output "iam_policy_json_document" {
    description = "the policy document for the ECS task role"
    value       = data.aws_iam_policy_document.app_task_role.json
}