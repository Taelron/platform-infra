// Run with: node --test (Node.js 23.6 or later strips the types).
import { test } from "node:test";
import { strict as assert } from "node:assert";
import { isAllowed as check, toObjectKey } from "./spaces.ts";

const READER = "eu-central-1_EXAMPLE_IdentityCenter";
const isAllowed = (uri: string, groups: readonly string[]) =>
  check(uri, groups, READER);

const none: string[] = [];
const reader = [READER];

test("a reader opens every page", () => {
  for (const uri of [
    "/",
    "/index.html",
    "/handbook/",
    "/platform/a/b/",
    "/fleetdesk/m1-mockups/home.png",
    "/assets/site.css",
    "/new-space/",
  ]) {
    assert.equal(isAllowed(uri, reader), true, uri);
  }
});

test("without the group, only the denied page and its assets", () => {
  assert.equal(isAllowed("/denied/", none), true);
  assert.equal(isAllowed("/assets/site.css", none), true);
  for (const uri of ["/", "/index.html", "/handbook/", "/platform/", "/assets", "/denied"]) {
    assert.equal(isAllowed(uri, none), false, uri);
  }
  assert.equal(isAllowed("/handbook/", ["docs-reader"]), false);
  assert.equal(check("/handbook/", [], ""), false);
});

test("encoded and dotted paths are refused", () => {
  for (const uri of [
    "/assets/../handbook/",
    "/assets/%2e%2e/handbook/",
    "/assets/..%2fhandbook/",
    "/%E0%A4%A",
    "/assets\\..\\handbook/",
  ]) {
    assert.equal(isAllowed(uri, none), false, uri);
    assert.equal(isAllowed(uri, reader), false, uri);
  }
});

test("a directory serves its index.html", () => {
  assert.equal(toObjectKey("/"), "/index.html");
  assert.equal(toObjectKey("/handbook/"), "/handbook/index.html");
  assert.equal(toObjectKey("/assets/site.css"), "/assets/site.css");
});
