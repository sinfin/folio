# AI Screenshot Capture

This script captures repeatable Folio AI UI states for local visual QA.

Run from the Folio root:

```bash
RAILS_ENV=test TEST_WITH_ASSETS=1 bundle exec ruby scripts/development/capture_ai_screenshots.rb
```

By default screenshots are written to:

```text
tmp/ai-screenshots-YYYYMMDD-HHMMSS/folio-dummy/
```

To combine Folio and host-app screenshots into one run folder, pass the same
root to both scripts:

```bash
AI_SCREENSHOT_ROOT=tmp/ai-screenshots-manual \
  RAILS_ENV=test TEST_WITH_ASSETS=1 \
  bundle exec ruby scripts/development/capture_ai_screenshots.rb
```

The script stubs `window.Folio.Api.apiPost` in the browser, so provider API keys
are not needed. It verifies the rendered frontend states: default action,
loading, variants, accept, ghost undo, error, and site prompt settings.

The PNG outputs are intentionally local artifacts under `tmp/` and must not be
committed.
