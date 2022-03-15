# modules/EFS

Terraform local module to create a EFS resource as a persistant storage volume for ECS tasks.

## How to use it

1. create VPC with at least one subnet where to mount tha access point.
2. create a security group that will be bound to the launched tasks that needs to get access to the volume.
3. call the module in tha main terraform script that create the infrastructure:

```tf
module "EFS" {
    source = "./modules/EFS"

    name = ""
    vpc_id = aws.vpc_id
    # ... rest of the required variables

}
```

Outputs are available by calling them this way :  `module.EFS._access_point_arn`