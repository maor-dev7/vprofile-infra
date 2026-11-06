terraform {
  backend "s3" {
    # Create this bucket before running terraform init, then replace the name if needed.
    bucket       = "gitops-terraformcode-313"
    key          = "vprofile-eks-cluster/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}