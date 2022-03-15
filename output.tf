output "vpc_id" {
    value = module.vpc.vpc_id
}

output "nat_ips" {
    value = module.vpc.nat_public_ips
}

output "security_group" {
    value = module.security_group_webserver.security_group_id
}

output "json_document" {
    value = module.efs.iam_policy_json_document
}

output "efs_security_point" {
    value = module.efs.security_group_id
}