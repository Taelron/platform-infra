// Taelron Docs: which paths a signed-in reader may open.
//
//   /, /index.html, /assets/*, /denied/*   any signed-in reader
//   /handbook/*                            group docs-handbook
//   /platform/*                            group docs-platform
//   /fleetdesk/*                           group docs-fleetdesk
//   anything else                          refused
//
// The path is decoded before it is matched, because S3 decodes it too: a
// request for /%68andbook/ must not slip past the handbook rule.

export const DENIED_PAGE = "/denied/index.html";

const OPEN_PREFIXES = ["assets", "denied"];

const SPACE_GROUPS: Readonly<Record<string, string>> = {
  handbook: "docs-handbook",
  platform: "docs-platform",
  fleetdesk: "docs-fleetdesk",
};

export function isAllowed(uri: string, groups: readonly string[]): boolean {
  let path: string;
  try {
    path = decodeURIComponent(uri);
  } catch {
    return false;
  }
  if (!path.startsWith("/") || path.includes("\\")) return false;

  const segments = path.slice(1).split("/");
  if (segments.some((s) => s === "." || s === "..")) return false;

  const [first] = segments;
  if (segments.length === 1 && (first === "" || first === "index.html")) {
    return true;
  }
  if (OPEN_PREFIXES.includes(first)) return true;

  const group = Object.hasOwn(SPACE_GROUPS, first)
    ? SPACE_GROUPS[first]
    : undefined;
  return group !== undefined && groups.includes(group);
}

export function toObjectKey(uri: string): string {
  return uri.endsWith("/") ? `${uri}index.html` : uri;
}
