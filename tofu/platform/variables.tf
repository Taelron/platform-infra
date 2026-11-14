# The single address allowed to SSH to the host: the outbound IP of the RHEL
# box Gaetan works from. Personal data in a public repository, so it is not in
# Git: GitHub Actions passes the secret ADMIN_SSH_CIDR, the RHEL box reads it
# at run time (README.md).
variable "admin_ssh_cidr" {
  description = "Admin source address for SSH, one /32"
  type        = string
  sensitive   = true

  validation {
    condition     = can(cidrhost(var.admin_ssh_cidr, 0)) && endswith(var.admin_ssh_cidr, "/32")
    error_message = "admin_ssh_cidr must be a single IPv4 address as /32."
  }
}
