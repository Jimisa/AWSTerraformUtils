output keys {
    value = flatten(var.containers_definition[*].mountPoints[*].persistant_storage)
}

output values {
    value = flatten(var.containers_definition[*].mountPoints[*].sourceVolume)
}

output match {
    value = matchkeys(flatten(var.containers_definition[*].mountPoints[*].sourceVolume),flatten(var.containers_definition[*].mountPoints[*].persistant_storage),[false])

}

output "zip" {
    value = [for prop in matchkeys(flatten(var.containers_definition[*].mountPoints[*].sourceVolume),flatten(var.containers_definition[*].mountPoints[*].persistant_storage),[true]):
        {"name"=prop}
    ]

}

output "efs_path" {
    value = [for efs in var.containers_definition[*]:
        zipmap(["id","path"],[efs.name,efs.logConfiguration.logDriver])
    ]
}

output "lookup_ap" {
    value = [
        for m_point in flatten(var.containers_definition[*].mountPoints):
            #[for m_point in c_def:
            {
                name = m_point.sourceVolume
                efs_configuration = [{
                    root_dir = m_point.containerPath
                    authorization_config = [{
                        access_point_id = join("",[for ap in var.access_point: ap.id if ap.path == m_point.containerPath])
                    }]
                }]
            } 
            #m_point.sourceVolume
            if m_point.persistant_storage
    ]
}