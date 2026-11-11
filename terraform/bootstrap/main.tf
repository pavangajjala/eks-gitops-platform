# Terraform installs Argo CD and one root Application, and nothing else.
# Everything running in the cluster after that is declared under gitops/ and
# reconciled by Argo CD, so there is a single place to look for what is deployed.

resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version

  values = [file("${path.module}/values/argocd.yaml")]

  atomic  = true
  timeout = 600
}

resource "helm_release" "root_app" {
  name      = "root"
  namespace = helm_release.argocd.namespace

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = var.argocd_apps_chart_version

  values = [yamlencode({
    applications = {
      root = {
        namespace  = "argocd"
        project    = "default"
        finalizers = ["resources-finalizer.argocd.argoproj.io"]

        source = {
          repoURL        = var.gitops_repo_url
          targetRevision = var.gitops_revision
          path           = "gitops/bootstrap"
        }

        destination = {
          server    = "https://kubernetes.default.svc"
          namespace = "argocd"
        }

        syncPolicy = {
          automated = {
            prune    = true
            selfHeal = true
          }
        }
      }
    }
  })]
}
