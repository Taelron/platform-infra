terraform {
  required_version = "~> 1.13.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.73.0"
    }
  }

  # The bucket below is created by this root. The first apply runs with a local
  # backend (backend_override.tf, not in Git), then the state moves here with
  # `tofu init -migrate-state`. See README.md.
  backend "s3" {
    bucket       = "platform-tofu-state-181841605684"
    key          = "bootstrap/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }
}
