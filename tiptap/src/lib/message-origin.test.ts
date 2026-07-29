import assert from "node:assert/strict";
import test from "node:test";

import { isSameOriginMessage } from "./message-origin.ts";

test("accepts messages from window.location.origin", () => {
  assert.equal(
    isSameOriginMessage(
      "https://books-cars.review.opinio.cz",
      "https://books-cars.review.opinio.cz",
    ),
    true,
  );
});

test("rejects messages from a different origin", () => {
  assert.equal(
    isSameOriginMessage(
      "https://attacker.example",
      "https://books-cars.review.opinio.cz",
    ),
    false,
  );
});
