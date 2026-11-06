# vprofile-infra

Terraform configuration for provisioning the AWS infrastructure used by the vProfile GitOps environment. It creates a VPC with two public subnets, an Amazon EKS cluster and managed node group, IAM roles, the EKS OIDC provider, and the EBS CSI add-on. The repository also contains an Argo CD ingress manifest for AWS Load Balancer Controller.

## Prerequisites

- Terraform 1.10 or later
- AWS CLI configured with credentials authorized to create EKS, EC2/VPC, IAM, and related resources
- `kubectl` for interacting with the cluster
- An existing S3 bucket for the configured Terraform backend
- AWS Load Balancer Controller installed in the cluster before applying the ingress manifest

## Configuration

Default Terraform settings are in `variables.tf`:

| Variable | Default | Description |
| --- | --- | --- |
| `region` | `us-east-1` | AWS region |
| `cluster_name` | `vprofile-eks-cluster` | EKS cluster name |
| `vpc_cidr` | `10.0.0.0/16` | VPC address range |
| `public_subnet_cidrs` | `10.0.1.0/24`, `10.0.2.0/24` | Public subnet ranges (exactly two required) |
| `node_instance_type` | `t3.large` | EKS worker instance type |
| `node_desired_size` | `1` | Desired node count |
| `node_min_size` | `1` | Minimum node count |
| `node_max_size` | `2` | Maximum node count |

The S3 backend is defined in `backend.tf`. Create the configured bucket before initialization, or update the backend settings to use your own bucket and region. Backend configuration cannot use Terraform input variables.

## Deploy

From the repository root:

1. Review and, if needed, update `backend.tf` and the Terraform defaults.
2. Initialize Terraform:

   ```sh
   terraform init
   ```

3. Review the proposed infrastructure changes:

   ```sh
   terraform plan
   ```

4. Apply the configuration:

   ```sh
   terraform apply
   ```

Terraform prints the cluster name, endpoint, and ARN as outputs. Configure `kubectl` for the newly created cluster with:

```sh
aws eks update-kubeconfig --region us-east-1 --name vprofile-eks-cluster
```

Adjust the region and cluster name if you changed the defaults.

## Argo CD ingress

`argocd-ingress.yaml` defines an internet-facing AWS Application Load Balancer ingress for the `argocd-server` service in the `argocd` namespace. Before applying it, confirm that the certificate ARN and ingress settings are appropriate for your AWS account and DNS setup, and that AWS Load Balancer Controller is installed:

```sh
kubectl apply -f argocd-ingress.yaml
kubectl get ingress -n argocd
```

## Destroy

Remove the Kubernetes ingress if it was applied, then destroy the Terraform-managed infrastructure when it is no longer needed:

```sh
kubectl delete -f argocd-ingress.yaml
terraform destroy
```

## State and credentials

Terraform state can contain sensitive infrastructure data. This configuration stores state in S3; protect the bucket with appropriate access controls, encryption, and backups. Do not commit state files, credentials, or secret variable files to Git.
