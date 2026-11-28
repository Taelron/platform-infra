# The two platform repositories, created by hand in Phase 2 and imported.
# Public, so nothing secret goes in; push protection blocks secrets on push.

import {
  for_each = local.repositories
  to       = github_repository.platform[each.key]
  id       = each.key
}

resource "github_repository" "platform" {
  for_each = local.repositories

  name       = each.key
  visibility = "public"

  has_issues      = true
  has_projects    = true
  has_wiki        = false
  has_discussions = false

  # Squash merge only (Versioning and Releases): the pull request title, in
  # Conventional Commits, becomes the one commit release-please reads.
  allow_merge_commit          = false
  allow_squash_merge          = true
  allow_rebase_merge          = false
  squash_merge_commit_title   = "PR_TITLE"
  squash_merge_commit_message = "BLANK"
  allow_auto_merge            = false
  delete_branch_on_merge      = false

  archive_on_destroy = true

  security_and_analysis {
    secret_scanning {
      status = "enabled"
    }
    secret_scanning_push_protection {
      status = "enabled"
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

# The Cluster API libvirt provider (CAPLV), forked from
# joshuagrisham/cluster-api-provider-libvirt (TAE-139, PO decision of
# 28 November 2026): Rancher's Cluster API creates the cluster VMs on the
# host's KVM through it. The fork carries Taelron's patch (the VM CPU in
# host-passthrough mode, which openSUSE Leap Micro 6 needs) and builds the
# image the platform deploys by digest. Public, like the upstream. Forked by
# hand (the app cannot create repositories) and imported.
import {
  to = github_repository.caplv
  id = "cluster-api-provider-libvirt"
}

resource "github_repository" "caplv" {
  name         = "cluster-api-provider-libvirt"
  description  = "Cluster API provider for libvirt, Taelron fork"
  fork         = true
  source_owner = "joshuagrisham"
  source_repo  = "cluster-api-provider-libvirt"
  visibility   = "public"

  has_issues      = true
  has_projects    = false
  has_wiki        = false
  has_discussions = false

  allow_merge_commit          = false
  allow_squash_merge          = true
  allow_rebase_merge          = false
  squash_merge_commit_title   = "PR_TITLE"
  squash_merge_commit_message = "BLANK"
  allow_auto_merge            = false
  delete_branch_on_merge      = false

  archive_on_destroy = true

  security_and_analysis {
    secret_scanning {
      status = "enabled"
    }
    secret_scanning_push_protection {
      status = "enabled"
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}
