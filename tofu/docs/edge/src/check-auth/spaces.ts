// Taelron Docs: which paths a signed-in reader may open.
//
//   group docs-reader            every page
//   signed in, without it        /assets/* and /denied/* only (the denied
//                                page and what it needs to display)
//
// The path is decoded before it is checked, because S3 decodes it too, and a
// path with "." or ".." segments or a backslash is refused for everyone.

export const DENIED_PAGE = "/denied/index.html";

export const READER_GROUP = "docs-reader";

const OPEN_PREFIXES = ["assets", "denied"];

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

  if (groups.includes(READER_GROUP)) return true;
  return segments.length > 1 && OPEN_PREFIXES.includes(segments[0]);
}

export function toObjectKey(uri: string): string {
  return uri.endsWith("/") ? `${uri}index.html` : uri;
}
