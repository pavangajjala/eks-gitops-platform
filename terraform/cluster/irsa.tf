# OIDC provider so Kubernetes service accounts can assume IAM roles (IRSA).

data "tls_certificate" "oidc" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "this" {
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]
}

locals {
  oidc_issuer = replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")

  # Service accounts that need AWS permissions. Each gets its own role that
  # only that service account, in that namespace, can assume.
  irsa_roles = {
    ebs-csi = {
      namespace       = "kube-system"
      service_account = "ebs-csi-controller-sa"
      policy_arns     = ["arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"]
    }
    external-secrets = {
      namespace       = "external-secrets"
      service_account = "external-secrets"
      policy_arns     = [aws_iam_policy.external_secrets.arn]
    }
  }

  irsa_attachments = merge([
    for name, role in local.irsa_roles : {
      for index, arn in role.policy_arns : "${name}-${index}" => { role = name, policy_arn = arn }
    }
  ]...)
}

data "aws_iam_policy_document" "irsa_assume" {
  for_each = local.irsa_roles

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.this.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer}:sub"
      values   = ["system:serviceaccount:${each.value.namespace}:${each.value.service_account}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "irsa" {
  for_each = local.irsa_roles

  name               = "${var.cluster_name}-${each.key}"
  assume_role_policy = data.aws_iam_policy_document.irsa_assume[each.key].json
}

resource "aws_iam_role_policy_attachment" "irsa" {
  for_each = local.irsa_attachments

  role       = aws_iam_role.irsa[each.value.role].name
  policy_arn = each.value.policy_arn
}

# External Secrets may read only secrets stored under this cluster's prefix.
data "aws_iam_policy_document" "external_secrets" {
  statement {
    actions = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = [
      "arn:${data.aws_partition.current.partition}:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:${var.cluster_name}/*",
    ]
  }
}

resource "aws_iam_policy" "external_secrets" {
  name   = "${var.cluster_name}-external-secrets"
  policy = data.aws_iam_policy_document.external_secrets.json
}
