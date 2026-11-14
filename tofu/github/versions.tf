terraform {
  required_version = "~> 1.13.0"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.13.0"
    }
  }

  # State next to the other roots; the apply role of GitHub Actions cannot
  # write it (bootstrap-guard).
  backend "s3" {
    bucket       = "platform-tofu-state-181841605684"
    key          = "github/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }
}
