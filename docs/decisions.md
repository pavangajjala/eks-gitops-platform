# Decisions and trade-offs

## Why Argo CD rather than Terraform-managed Helm releases

Managing add-ons with `helm_release` works at first, then causes three
problems: every chart upgrade needs cluster credentials in the Terraform
pipeline, drift inside the cluster goes unnoticed until the next apply, and
the plan output for a large chart is unreadable. With Argo CD the cluster
pulls its own configuration, drift is corrected continuously, and Terraform
needs Kubernetes access only once, for the bootstrap.

## Why managed node groups and not Karpenter

Managed node groups are enough for a small, predictable platform and have no
moving parts inside the cluster. Karpenter is the right next step once
workloads need many instance shapes or fast scale-up; it would be added as
another platform Application, with its IAM role next to the existing IRSA
roles.

## Why IRSA when Pod Identity exists

The Pod Identity agent is installed, and new roles can use it. The two
existing roles use IRSA because the EBS CSI add-on and the External Secrets
chart both support it without extra association resources, and IRSA trust
policies make the namespace and service account restriction visible in one
place.

## Sync ordering

The policies Application needs Kyverno's CRDs. Instead of relying on ordering
between Applications, it sets `SkipDryRunOnMissingResource` and retries with
backoff. The first sync of a new cluster may show the policies as out of sync
for a minute or two, then settle.

## Kyverno exclusions

Platform namespaces are excluded from the pod policies because node agents
(CNI, CSI, Prometheus node exporter) need host access. The exclusion list is
explicit, so adding a new platform namespace is a reviewed change.

## What I would add for a real production cluster

- SSO for Argo CD (Dex or the built-in OIDC) and the admin user disabled
- An ingress or Gateway for Argo CD and Grafana behind the internal load balancer
- Backups with Velero and a tested restore
- Separate clusters, not namespaces, for dev and prod
- Alert routing from Alertmanager to an on-call tool
