variable "region" {
  description = "AWS region of the cluster."
  type        = string
  default     = "eu-west-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster to bootstrap."
  type        = string
}

variable "gitops_repo_url" {
  description = "Git repository Argo CD syncs from."
  type        = string
  default     = "https://github.com/pavangajjala/eks-gitops-platform.git"
}

variable "gitops_revision" {
  description = "Branch or tag Argo CD tracks."
  type        = string
  default     = "main"
}

variable "argocd_chart_version" {
  description = "Version of the argo-cd Helm chart."
  type        = string
  default     = "10.17.2"
}

variable "argocd_apps_chart_version" {
  description = "Version of the argocd-apps Helm chart."
  type        = string
  default     = "2.0.8"
}
