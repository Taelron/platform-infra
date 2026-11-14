# Inventory of one OpenTofu root, from `tofu show -json` of its state.
#
# Keeps, for each taggable AWS resource: address, type, name, Project,
# Component, region and an allowlist of non-sensitive fields per type.
# Untaggable resources (attachments, policy links, bucket settings, ...) are
# only counted. Nothing else leaves: no policy document, no user data, no
# output, and no value OpenTofu marks sensitive.
#
# Arguments: --arg root, --arg generated_at, --arg commit.

def managed_aws:
  [.values.root_module.resources[]?, (.values.root_module.child_modules[]?.resources[]?)]
  | map(select(.mode == "managed" and (.provider_name | test("hashicorp/aws$"))));

# A value is kept only if it is not marked sensitive.
def safe($r; $key):
  if ($r.sensitive_values[$key] // false) == true then null else $r.values[$key] end;

def name_of($r):
  ($r.values.tags_all.Name // null)
  // safe($r; "name") // safe($r; "bucket") // safe($r; "function_name")
  // safe($r; "key_name") // ($r.values.aliases[0]? // null)
  // safe($r; "domain_name") // safe($r; "url") // $r.address;

managed_aws as $all
| ($all
   | map(select(.type == "aws_s3_bucket_versioning"))
   | map({key: .values.bucket, value: (.values.versioning_configuration[0].status // null)})
   | from_entries) as $versioning
| ($all | map(select(.values | has("tags_all")))) as $tagged
| {
    root: $root,
    generated_at: $generated_at,
    commit: $commit,
    untaggable: (($all | length) - ($tagged | length)),
    resources: [
      $tagged[] as $r
      | {
          address: $r.address,
          type: $r.type,
          name: name_of($r),
          project: ($r.values.tags_all.Project // null),
          component: ($r.values.tags_all.Component // null),
          region: ($r.values.region // "global"),
          details: (
            if   $r.type == "aws_instance"        then {type: safe($r; "instance_type"), state: safe($r; "instance_state")}
            elif $r.type == "aws_ebs_volume"      then {size_gib: safe($r; "size"), type: safe($r; "type")}
            elif $r.type == "aws_acm_certificate" then {status: safe($r; "status")}
            elif $r.type == "aws_s3_bucket"       then {versioning: $versioning[$r.values.bucket]}
            else {} end
            | with_entries(select(.value != null))
          )
        }
    ] | sort_by(.project, .component, .type, .name)
  }
