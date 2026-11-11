# Core add-ons are managed by EKS so they are upgraded together with the
# control plane instead of drifting behind it.

locals {
  addons = {
    vpc-cni                = {}
    kube-proxy             = {}
    coredns                = {}
    eks-pod-identity-agent = {}
    aws-ebs-csi-driver     = { role_arn = aws_iam_role.irsa["ebs-csi"].arn }
  }
}

resource "aws_eks_addon" "this" {
  for_each = local.addons

  cluster_name             = aws_eks_cluster.this.name
  addon_name               = each.key
  service_account_role_arn = try(each.value.role_arn, null)

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  # CoreDNS and the CSI controller need nodes to schedule on.
  depends_on = [aws_eks_node_group.this]
}
