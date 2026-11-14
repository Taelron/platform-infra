// Run with: node --test (Node.js 23.6 or later strips the types).
import { test } from "node:test";
import { strict as assert } from "node:assert";
import { isAllowed, toObjectKey } from "./spaces.ts";

const none: string[] = [];
const handbook = ["docs-handbook"];

test("open paths need no group", () => {
  for (const uri of ["/", "/index.html", "/assets/site.css", "/denied/"]) {
    assert.equal(isAllowed(uri, none), true, uri);
  }
});

test("each space needs its group", () => {
  assert.equal(isAllowed("/handbook/", handbook), true);
  assert.equal(isAllowed("/handbook/a/b/", handbook), true);
  assert.equal(isAllowed("/handbook/", none), false);
  assert.equal(isAllowed("/platform/", handbook), false);
  assert.equal(isAllowed("/platform/", ["docs-platform"]), true);
  assert.equal(isAllowed("/fleetdesk/", ["docs-fleetdesk"]), true);
  assert.equal(isAllowed("/fleetdesk/", handbook), false);
});

test("unknown paths are refused", () => {
  for (const uri of ["/other/", "/favicon.ico", "//handbook/", "/Handbook/"]) {
    assert.equal(isAllowed(uri, handbook), false, uri);
  }
  assert.equal(isAllowed("/constructor/", handbook), false);
  assert.equal(isAllowed("/__proto__/", handbook), false);
});

test("encoded and dotted paths cannot reach a space", () => {
  for (const uri of [
    "/%68andbook/",
    "/assets/../handbook/",
    "/assets/%2e%2e/handbook/",
    "/assets/..%2fhandbook/",
    "/assets%2f..%2fhandbook/",
    "/%E0%A4%A",
    "/assets\\..\\handbook/",
  ]) {
    assert.equal(isAllowed(uri, none), false, uri);
  }
  assert.equal(isAllowed("/%68andbook/", handbook), true);
});

test("a directory serves its index.html", () => {
  assert.equal(toObjectKey("/"), "/index.html");
  assert.equal(toObjectKey("/handbook/"), "/handbook/index.html");
  assert.equal(toObjectKey("/assets/site.css"), "/assets/site.css");
});
