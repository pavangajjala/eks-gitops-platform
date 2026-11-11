cluster_name = "platform-dev"
region       = "eu-west-1"

vpc_id             = "vpc-0123456789abcdef0"
private_subnet_ids = ["subnet-0aaa1111bbbb2222c", "subnet-0ddd3333eeee4444f", "subnet-0abc5555def66667a"]

# Leave empty to keep the API private; otherwise list VPN or office ranges.
public_endpoint_cidrs = ["203.0.113.0/24"]

admin_role_arns = [
  "arn:aws:iam::222222222222:role/aws-reserved/sso.amazonaws.com/eu-west-1/AWSReservedSSO_AdministratorAccess_0123456789abcdef",
]

node_groups = {
  system = {
    instance_types = ["m7g.large"]
    min_size       = 2
    max_size       = 4
    desired_size   = 2
    labels         = { "node-role" = "system" }
  }
  apps-spot = {
    instance_types = ["m7g.large", "m6g.large", "c7g.large"]
    capacity_type  = "SPOT"
    min_size       = 0
    max_size       = 10
    desired_size   = 2
    labels         = { "node-role" = "apps" }
  }
}
