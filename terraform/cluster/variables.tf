variable "region" {
  description = "AWS region for the cluster."
  type        = string
  default     = "eu-west-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes minor version for the control plane and node groups."
  type        = string
  default     = "1.35"
}

variable "vpc_id" {
  description = "VPC the cluster runs in."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets for the control plane ENIs and worker nodes."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "EKS needs subnets in at least two availability zones."
  }
}

variable "public_endpoint_cidrs" {
  description = "CIDR ranges allowed to reach the public API endpoint. Empty disables the public endpoint."
  type        = list(string)
  default     = []

  validation {
    condition     = !contains(var.public_endpoint_cidrs, "0.0.0.0/0")
    error_message = "Do not expose the Kubernetes API to the whole internet; list your VPN or office ranges."
  }
}

variable "admin_role_arns" {
  description = "IAM roles (for example Identity Center permission set roles) granted cluster-admin."
  type        = list(string)
  default     = []
}

variable "node_groups" {
  description = "Managed node groups keyed by name."
  type = map(object({
    instance_types = list(string)
    capacity_type  = optional(string, "ON_DEMAND")
    min_size       = number
    max_size       = number
    desired_size   = number
    labels         = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = optional(string)
      effect = string
    })), [])
  }))

  default = {
    system = {
      instance_types = ["m7g.large"]
      min_size       = 2
      max_size       = 4
      desired_size   = 2
      labels         = { "node-role" = "system" }
    }
  }
}

variable "log_retention_days" {
  description = "Retention for control plane logs."
  type        = number
  default     = 90
}
