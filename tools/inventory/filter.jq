# Inventory of one OpenTofu root, from `tofu show -json` of its state.
#
# Keeps, for each taggable AWS resource: address, type, name, Project,
# Component, region and a one-line summary built from an allowlist of
# non-sensitive fields per type. Untaggable resources (attachments, policy
# links, bucket settings, ...) and security group rules are only counted.
# Nothing else leaves: no policy document, no user data, no output, and no
# value OpenTofu marks sensitive.
#
# Arguments: --arg root, --arg generated_at, --arg commit.

def managed_aws:
  [.values.root_module.resources[]?, (.values.root_module.child_modules[]?.resources[]?)]
  | map(select(.mode == "managed" and (.provider_name | test("hashicorp/aws$"))));

# A value is kept only if it is not marked sensitive.
def safe($r; $key):
  if ($r.sensitive_values[$key] // false) == true then null else $r.values[$key] end;

# Counted, not listed: one row per firewall rule says little to a reader.
def counted_only: .type | test("^aws_vpc_security_group_(ingress|egress)_rule$");

def name_of($r):
  (if $r.type == "aws_lb_listener" and safe($r; "protocol") != null
   then "\(safe($r; "protocol")) listener" else null end)
  // ($r.values.tags_all.Name // null)
  // safe($r; "name") // safe($r; "bucket") // safe($r; "function_name")
  // safe($r; "key_name") // ($r.values.aliases[0]? // null)
  // safe($r; "domain_name") // safe($r; "url") // $r.address;

managed_aws as $all
| ($all
   | map(select(.type == "aws_s3_bucket_versioning"))
   | map({key: .values.bucket, value: (.values.versioning_configuration[0].status // null)})
   | from_entries) as $versioning
| ($all | map(select((.values | has("tags_all")) and (counted_only | not)))) as $tagged
| {
    root: $root,
    generated_at: $generated_at,
    commit: $commit,
    not_listed: (($all | length) - ($tagged | length)),
    resources: [
      $tagged[] as $r
      | {
          address: $r.address,
          type: $r.type,
          name: name_of($r),
          project: ($r.values.tags_all.Project // null),
          component: ($r.values.tags_all.Component // null),
          region: ($r.values.region // "global"),
          # Recorded at the last apply, not a live reading: the page's column
          # is headed "At last apply" (the host stops every night).
          summary: (
            if $r.type == "aws_instance" then
              [safe($r; "instance_type"),
               safe($r; "instance_state")]
            elif $r.type == "aws_ebs_volume" then
              [[(safe($r; "size") | if . then "\(.) GB" else null end), safe($r; "type")]
               | map(select(. != null)) | join(" ")]
            elif $r.type == "aws_acm_certificate" then
              [safe($r; "status") | if . then ascii_downcase else null end]
            elif $r.type == "aws_s3_bucket" then
              [$versioning[$r.values.bucket] | if . then "versioning \(ascii_downcase)" else null end]
            elif $r.type == "aws_lambda_function" then
              [safe($r; "runtime")]
            elif $r.type == "aws_cloudfront_distribution" then
              [safe($r; "status") | if . then ascii_downcase else null end]
            elif $r.type == "aws_lb" then
              [safe($r; "load_balancer_type") | if . then "\(.) load balancer" else null end]
            else [] end
            | map(select(. != null)) | join(", ") | if . == "" then null else . end
          )
        }
    ] | sort_by(.project, .component, .type, .name)
  }
