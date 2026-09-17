# Folio and main_app technical roadmap

**Baseline date:** 2026-09-14

**Baseline revisions:** Folio `bd9686a8`; current main_app checkout `ff90805d`

## Executive recommendation

Do the work in this order:

1. Upgrade Folio and main_app to Rails 8.1, Ruby 4, and Bundler 4 as one
   coordinated change, followed by one QA regression.
2. Rebuild the cache work from the old branches as a small, observable cache
   pack; do not rebase or merge the old branches wholesale.
3. Build one Folio select for normal selects, multiselects, ordering, tags,
   remote data, and filters. Use it while migrating menu administration, remove
   the legacy React application, and update retained dependencies in the same
   change before one QA regression pass.
4. Continue the Cells-to-components and jQuery-to-Stimulus cleanup, then move
   cohesive optional domains into Packwerk packs.
5. Keep on-demand image delivery as the final phase. Choose and prove the
   underlying technology before committing to its implementation.

## Current baseline

| Area | Folio | main_app | Consequence |
|---|---:|---:|---|
| Ruby | 3.3.3 | 3.3.12 | Both need Ruby 4 verification; Folio is also behind the latest 3.3 security patch. |
| Rails | 8.0.4.1 | 8.0.5.1 with `< 8.1` constraint | Folio must support 8.1 before main_app can remove its cap. |
| Framework defaults | 8.0 | 8.0 | Move defaults to 8.1 explicitly and treat deprecations as upgrade work. |
| Cell classes | 90 production classes | 1 local class | Most implementation work is in Folio. |
| Cell calls | 160 production calls | 31 production calls into Folio | Compatibility releases must let main_app migrate incrementally. |
| Cell footprint | 11,264 lines; 112 Slim, 35 JS, 60 style, 65 test files | Small local footprint | This is a multi-release migration, not one PR. |
| jQuery-bearing JS | 40 files, 249 matches | 13 files, 33 matches | About half of Folio's affected files are Cell sidecars and should migrate with their Cells. |
| Components | 218 classes including packs/dummy components | 506 classes | main_app is already component-heavy; its work is mainly Folio call sites and interop. |
| Direct outdated gems | Dozens; several constrained majors | Dozens; major gaps include job processing, error reporting, and support libraries | Handle runtime blockers in R0, then update the rest together in R2. |
| Frontend dependency hotspots | Legacy React 16 administration application (~13k source lines), several select implementations, Bower-era vendor tree, current Tiptap application | Small root npm surface | Consolidate selects under one Folio API, migrate menu administration, then remove the legacy React application. |
| Packwerk | Root enforcement and one AI pack are active | Loader/config exists, but only a non-enforced root package | Folio can add packs directly; main_app needs a first boundary plus CI enforcement. |

As of the baseline date, Ruby 4.0.6 is the current Ruby 4 release, while Ruby
3.3 is in security maintenance until March 2027. Rails 8.1.3.1 is current; the
Rails team moved 8.0 to security-only maintenance in May 2026. Therefore the
runtime work is preventative maintenance with a real support deadline, not a
cosmetic upgrade.

Sources: [Ruby releases](https://www.ruby-lang.org/en/downloads/releases/),
[Ruby 3.3 maintenance notice](https://www.ruby-lang.org/en/news/2026/03/26/ruby-3-3-11-released/),
[Rails 8.1 release notes](https://guides.rubyonrails.org/8_1_release_notes.html),
[Rails 8.0/8.1 support notice](https://rubyonrails.org/2026/3/24/Rails-Versions-8-0-5-and-8-1-3-have-been-released).

## Roadmap

### R0 — Runtime and framework upgrade

**Goal:** upgrade Folio and main_app to Rails 8.1, Ruby 4, and Bundler 4
together, then give QA the completed cross-repository change once.

Delivery sequence:

1. Upgrade Folio to Rails 8.1, Ruby 4.0.6, and Bundler 4 together. Enable Rails
   8.1 defaults and resolve deprecations and dependency constraints.
2. Use that Folio version in main_app while upgrading its Rails, Ruby, and
   Bundler versions in the same workstream, including Docker, CI, native
   packages, and deployment scripts.
3. Run both automated test suites against the completed combined upgrade.
4. Give QA the full Folio and main_app change for one regression pass, then
   deploy it together.

Exit criteria:

- Rails 8.1 defaults are explicit in both repositories.
- Both repositories run on Ruby 4.0.6, Rails 8.1, and Bundler 4.
- No untriaged upgrade deprecations remain in representative requests or jobs.
- The combined change passes the automated suites and one full QA regression.

### R1 — Cache rework

**Goal:** replace the global cache reset with targeted invalidation, so a change
only clears content affected by that change.

The current main_app cache key is referenced 104 times across 33 files. It is
calculated from ten database tables, and every update changes it, including
updates to unpublished records. This effectively clears all application caches.
Cloudflare already does the heavy lifting for public-page delivery; this work
should focus on the Rails caches behind it.

Use the old work as reference material:

- Reuse the cache pack, key helpers, invalidation code, and tests from
  `origin/petr/cache`, porting them onto current master instead of merging the
  stale branch.
- Use the main_app cache branches as an inventory of call sites, not as code to
  merge.
- Leave record caching out unless the before/after test shows that it is needed.

Delivery sequence:

1. Add a local automated test that runs heavy frontend traffic while creating,
   editing, publishing, and unpublishing records through `/console`. Record
   request timings, database work, and cache hits before the migration.
2. Port the Folio cache pack and targeted invalidation onto current master.
3. Fully migrate the main_app call sites and remove the global cache key.
4. Run the same automated test and compare the results with the baseline.
5. Hand the complete migration to QA for full application testing.

Exit criteria:

- The local test covers simultaneous `/console` activity and heavy frontend
  visits, and reports comparable before/after measurements.
- Unpublished and unrelated updates no longer clear all cached content.
- Published changes appear on the frontend without manual cache clearing.
- The global cache-key query and its compatibility code are gone.

### R2 — Dependency modernization and legacy React removal

**Goal:** update the retained dependencies and remove the legacy React
application in one coordinated change, followed by one full QA regression.

Delivery sequence:

1. During R0, update only the libraries needed for Ruby 4 and Rails 8.1.
2. Add one Folio-owned select input and Stimulus controller. Its modes cover
   single select, multiselect, ordered multiselect, tags, local or remote search,
   and console filters.
3. Migrate the existing Folio and main_app select variants to the shared input.
   The underlying JavaScript library remains an implementation detail behind
   the Folio API.
4. Migrate menu administration to ViewComponents and Stimulus. Menu target
   selection uses the new Folio select; the rest of menu editing remains its own
   component behavior.
5. Delete the legacy React administration application, its build pipeline,
   React 16 dependencies, and integration code. Ordered multiselect is now a
   mode of the Folio select, not a separate application.
6. Update the remaining Ruby and JavaScript libraries together, including major
   updates. Keep the separate Tiptap/React 19 application current, and remove
   obsolete select integrations and unused Bower assets.
7. Run the automated test suite, then give QA the complete change for one
   regression pass. Do not split this into dependency-family releases.

Dependencies owned by later removals—Cells in R3, jQuery plugins in R4, and
Dragonfly image processing in R6—should be removed in those phases rather than
upgraded only to be deleted.

Exit criteria:

- Normal, multiple, ordered, tag, remote, and filter selects use the same
  Folio-owned input API.
- Menu administration works without the legacy React application and uses the
  Folio select for target selection.
- The legacy React application, build pipeline, and React 16 dependencies are
  gone.
- All retained dependencies have been updated together.
- The combined change passes the automated suite and one full QA regression.

### R3 — Cells to ViewComponent

**Goal:** remove the Cells runtime and its host-application API while preserving
rendered behavior and enabling colocated Stimulus code.

Migrate in release-sized vertical batches:

1. Leaf/presentational Cells.
2. Authentication and shared public Cells.
3. Console catalogue, forms, state, and navigation Cells.
4. File/media Cells while preserving the current image API; do not block this
   migration on the R6 technology decision.
5. main_app call sites and its one local Cell.
6. Remove `cells-rails`, `cells-slim`, base Cell classes, asset requires, and
   compatibility helpers only after cross-repository searches are clean.

Each batch uses generated ViewComponents, explicit initializer APIs,
rendered-output tests, BEM-compatible assets, and a Folio deprecation/release
note when host-facing APIs change. Migrate the Cell's JavaScript in the same
batch; that work is included here and excluded from R4.

Exit criteria:

- No production Cell class, `cell(...)` call, Cell test base, or Cell asset
  manifest remains in either repository.
- All replacements have behavior-facing component/integration coverage.
- Cells gems are removed from Folio and main_app.

### R4 — Vanilla JavaScript and Stimulus

**Goal:** application-owned interaction uses component-scoped Stimulus and
native DOM APIs; jQuery and its remaining plugin chain can be removed.

This workstream covers JavaScript outside the Cell migrations:

- Convert global/delegated handlers to owner components and Stimulus actions.
- Replace jQuery AJAX with the existing Folio API wrapper and native DOM
  updates.
- Preserve temporary native/jQuery event bridges only while main_app callers
  still need them.
- Replace or upgrade jQuery-bound plugins, then remove `jquery-rails`, jQuery UI,
  and obsolete Bower assets.
- Add browser-level tests for meaningful interaction instead of asserting asset
  source text.

Exit criteria:

- No application-owned `$(`, `jQuery`, or global delegated feature handler
  remains.
- Every manually registered listener/observer has lifecycle cleanup.
- jQuery is absent from the shipped dependency and asset graph.

### R5 — Additional Packwerk packs

**Goal:** use enforced boundaries for optional/cohesive functionality, not as a
directory-moving exercise.

The cache pack is delivered in R1 and is not counted again here. Good next
candidates based on current coupling are:

- Folio: provider-specific media integrations, currently small and referenced
  from only a few files outside their named areas. Defer these until R6 defines
  the new file/image boundary.
- main_app first pack: mobile API (about 56 named files and one external
  reference).
- main_app second pack: external-data/import integration (about 27 named files
  and five external references).

For each pack, define its public API first, move code with its tests/assets,
declare dependencies, enable Packwerk validation/check in CI, and remove root
references to pack-owned implementation constants.

Do not choose the entitlement/subscription integration as the first main_app
pack. It currently spans about 204 named files and has 126 referencing files
outside that path. Establishing an API boundary there is valuable, but it is a
separate follow-up after the first two packs prove the pattern.

### R6 — On-demand image delivery

**Status:** the direction is agreed, but the underlying technology is not yet
selected.

**Goal:** original files have stable object identities; derivatives are
addressed by deterministic URLs and generated by an image service on first
request, then cached at the edge. Normal page rendering must not enqueue or run
thumbnail generation.

The existing path couples `thumb(size)` to Dragonfly, Sidekiq jobs, persisted
`thumbnail_sizes`, temporary placeholder URLs, MessageBus updates, and
pregeneration callbacks. main_app adds site-specific variant matrices, exports,
RSS/metadata consumers, imports, and a thumbnail job override. There are 40
explicit production `thumb` calls in 26 main_app files, but the compatibility
surface is wider because many components receive already-built thumbnail data.

Treat `origin/jzlamal/aws-file-handler` as a discarded prototype. The branch is
689 Folio commits behind and 202 commits ahead overall; only 13 commits are
specifically about the handler. Its final state still contains hard-coded
temporary object URLs, unresolved site and MIME handling, a private gem, a
second file table, and partially integrated Lambda/SQS flows. Reuse the upload
and processing requirements, not the code.

Required architecture decisions from a focused proof of concept:

- Select the processing service and ownership model: managed AWS pipeline or a
  maintained image proxy behind the CDN.
- Define a signed, canonical variant URL containing source identity, geometry,
  crop/focal point, format, quality, and an implementation version.
- Restrict dimensions and operations to prevent an unbounded transformation or
  denial-of-service surface.
- Make public variants immutable and long-cacheable. A changed crop or original
  must produce a new URL rather than require global purging.
- Specify private-file authorization separately; public image URLs cannot be
  reused as the private attachment design.
- Preserve metadata extraction, admin preview/crop behavior, import flows, and
  modern formats such as WebP/AVIF/HEIC.

Delivery sequence:

1. Prove the URL contract end to end with representative originals, crops,
   formats, failures, and all site variants. Measure first-hit and cached-hit
   latency and cost.
2. Add a Folio image-variant abstraction. Keep a temporary `thumb(...).url`
   compatibility adapter so host applications can migrate incrementally.
3. Route newly uploaded public images through stable original keys and the new
   URL builder. Keep old image records readable.
4. Migrate main_app consumers by risk: components, responsive `srcset`, OG and
   structured data, RSS/export feeds, admin crop UI, imports, and bulk jobs.
5. Dual-read in production, monitor errors and origin load, and backfill only
   metadata or object identity that the URL contract actually needs.
6. Stop pregeneration and generation jobs. After the rollback window, remove
   image `thumbnail_sizes` writes, temporary URLs, image-specific Dragonfly
   processing, and obsolete dependencies/data.

Exit criteria:

- A cache miss is processed outside the Rails request and Sidekiq paths.
- Every transformation URL is deterministic, signed/validated, observable, and
  CDN-cacheable.
- Existing image URLs continue to work for the migration/SEO retention window.
- Crop/focal-point changes result in new URLs and all public-site, feed, and
  admin flows pass regression checks.
- Pregeneration no longer creates queue or database write storms.

This phase removes Dragonfly from the public image-processing path. A full
Dragonfly retirement for private attachments, session uploads, audio/video, and
application-owned PDFs remains a separate follow-up unless folded into a
broader file-storage programme.

## Programme milestones

| Milestone | Scope | Dependency | Recommended delivery shape |
|---|---|---|---|
| M1 | R0 runtime | None | Upgrade Folio and main_app to Rails 8.1, Ruby 4, and Bundler 4 together, then run one QA regression. |
| M2 | R1 cache | M1 | Local before/after test, Folio cache pack, full main_app migration, then QA. |
| M3 | R2 dependencies and legacy React removal | M1 | Build and adopt the shared Folio select, migrate menu administration, remove the legacy application, update retained dependencies, then run one QA regression. |
| M4 | R3-R4 Cells and JavaScript | M1 | Small vertical PRs, normally 4-8 Cells or one plugin family at a time. |
| M5 | R5 packs | Cache pack lands in M2; other packs follow stable boundaries | One pack per delivery, with CI enforcement before starting the next. |
| M6 | R6 images | Earlier priorities complete | Choose and prove the technology, then migrate if the result is viable. |

Start the R6 implementation only after its proof of concept selects a viable
technology.

## Programme rules

- Folio changes land and release before dependent main_app removals.
- Every migration has compatibility, observability, rollback, and a defined
  removal milestone; compatibility layers are not permanent architecture.
- Do not combine a framework upgrade, data migration, and behavioral rewrite in
  one deployment.
- Prefer immutable/versioned cache keys over broad deletion and CDN purges.
- Treat staged files as reviewed and preserve the index during all roadmap work.
- Re-run dependency and code-footprint inventories at the start of each
  workstream; the numbers in this document are a dated baseline.
