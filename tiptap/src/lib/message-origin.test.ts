import assert from "node:assert/strict";
import test from "node:test";

import { isSameOriginMessage } from "./message-origin.ts";

test("accepts messages from window.location.origin", () => {
  assert.equal(
    isSameOriginMessage("https://cms.example.test", "https://cms.example.test"),
    true,
  );
});

test("rejects messages from a different origin", () => {
  assert.equal(
    isSameOriginMessage("https://attacker.example", "https://cms.example.test"),
    false,
  );
});
