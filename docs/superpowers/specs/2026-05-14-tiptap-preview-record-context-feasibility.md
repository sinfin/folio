# Tiptap Editor Preview — Record-Aware Rendering: Feasibility Analysis

**Status:** Feasibility study — not approved for implementation. Requires project-leader sign-off on the central architectural question before planning proceeds.

**Date:** 2026-05-14

**Scope:** Folio (`folio/`) and downstream consumer (`smilemusic/`). The motivating use case is Smilemusic's list-articles Tiptap nodes, but the proposed mechanism is generic.

## 1. Motivation

Some Tiptap nodes (in Smilemusic: list-articles nodes — see `app/components/publisher/tiptap/node/listings/articles/index_component.rb` and friends) render content that depends on the **placement record** they belong to. In production rendering, the controller for that record (e.g. `Publisher::List::BaseController`) sets up a `Publisher::ListArticlesPicker` bound to the record, and the node component reads articles from it.

The editor preview path is different. The editor's iframe asks `Folio::Console::Api::TiptapController#render_nodes` to render each node it displays. That controller is record-agnostic by design — it knows only the node attrs the editor sent. As a result, the node component finds no picker (`controller.list_articles_picker` is nil) and falls back to a static placeholder via the `console_preview?` short-circuit in `Publisher::TiptapNodeComponentWithListArticles`.

The placeholder is satisfactory today. The goal of this work is to replace it with the **exact articles** the picker would produce for the record being edited, so the editor reflects production output. A "representative but different" preview is explicitly rejected — that would reduce editor clarity, not improve it.

## 2. The Architectural Tension

Two rules constrain the solution space:

1. `Folio::Console::Api::TiptapController#render_nodes` must remain record-agnostic. Its request payload carries node attributes only; it does not accept a placement reference.
2. `TiptapInput` must remain ignorant of the placement record beyond what it already exposes today (`placement_type` / `placement_id` are sent to the JS controller for autosave only, and consumed by a *different* controller — `TiptapRevisionsController`). The input is "purely an editor mount point".

Matching production exactly requires a `ListArticlesPicker.new(record: <placement>, ...)` to run inside the render_nodes request. That means the placement record's identity must reach the render_nodes request via some channel.

**The design space reduces to one question:** what non-input, non-render_nodes-payload channel can carry placement identity from the host console page to the render_nodes request?

## 3. Candidate Channel Families

Four families were considered. Each preserves the two rules to different degrees and incurs different costs.

### A — Opaque preview-context token, resolved server-side via Folio hook (recommended)

The host console controller (the one rendering the form) mints a random token, stashes the placement context in a server-side cache against that token, and passes the token through the form to the input. The input forwards the token to render_nodes. Folio's TiptapController runs a host-registered resolver callable that exchanges the token for record context and exposes the picker on the controller. TiptapController itself never learns what the token means.

- **Preserves rule 1:** TiptapController treats the token as opaque; it just hands it to a host callable.
- **Preserves rule 2 (partially):** TiptapInput grows by one *opaque* option. The token does not reveal record identity to the input, but it is a side-channel for record context. **This is the question the leader must rule on** — see §5.
- **Production parity:** identical code paths. The same picker, the same `pick(count:, root_index:)` call, the same article objects.
- **Multi-tab/multi-record safe:** each form-render mints a unique token; tabs cannot collide.
- **Authorization:** the resolver is host code; it validates the cached `user_id` matches `Folio::Current.user.id` and `site_id` matches `Folio::Current.site.id` before exposing the picker.
- **Cache TTL bound:** very long editor sessions exceed TTL; mitigations are documented in §4.

### B — Cache keyed by `(user, site, attribute_name)`, no token

Same mechanism as A, but the cache key is derived from request context alone (current user, current site, attribute name). No new input option, no token in the render_nodes payload.

- **Preserves rule 2 most strictly:** TiptapInput is genuinely unchanged.
- **Multi-tab/multi-record unsafe:** same user editing two records (same attribute name) in two tabs → second overwrites first; first tab silently previews the wrong record's articles. Editorial workflows do hit this case. Failure mode is silent and confusing.
- **Implicit coupling:** every host request that renders the form must populate the cache, including refreshes after validation failures, turbo-frame re-renders, etc.

### C — Bypass TiptapController via parent-window postMessage

The iframe emits its render request; the parent stimulus controller intercepts requests for node types registered as "host-rendered" and routes them, via CustomEvent + the host page's own JS, to a host-owned preview controller (which has the record id from the page's data attributes). HTML flows back through the chain to the iframe.

- **Preserves both rules literally:** Folio's TiptapController is not touched. No new input option.
- **JS choreography is significantly more complex:** iframe ↔ parent stimulus ↔ host page DOM ↔ host controller ↔ back. Folio's stimulus controller needs a new registry for "delegated node types".
- **End-to-end paths to redesign:** render, paste, re-render-on-edit, loading states, error states.
- **Higher maintenance burden;** harder to test.

### D — Pre-render previews at form-render time

Host console controller walks `@list.tiptap_content`, server-renders each list-article node (it has the record), and embeds HTML inline in the page. JS substitutes inline HTML for those node types instead of calling render_nodes.

- **Preserves both rules:** Folio is untouched.
- **Doesn't cover new or edited nodes.** Newly inserted nodes still go through render_nodes with no record context; editing a node's `manual_list_article_count` or `root_index` likewise. Only nodes present at page load and never edited get real previews. This effectively means most editing sessions still see placeholders.

## 4. Recommended Approach: A — Detailed Design

### 4.1 Components and changes

| File | Change |
|---|---|
| `folio/app/inputs/tiptap_input.rb` | Add one option: `preview_context_token` (opaque string, default nil). Wire into stimulus values. |
| `folio/app/assets/javascripts/folio/input/tiptap.js` | Add `previewContextToken: String` value; include it in render_nodes POST body when present. Paste flow may need it too if list nodes are pasteable. |
| `folio/app/controllers/folio/console/api/tiptap_controller.rb` | Add `before_action :run_preview_context_resolver, only: [:render_nodes, :paste]`. The action reads the token from params, validates presence, calls `Folio::Tiptap.config.preview_context_resolver.call(self, token)` if configured. |
| `folio/lib/folio/tiptap.rb` (or wherever config is held) | Add `config_accessor :preview_context_resolver` (a `Proc`/callable). |
| `folio/app/components/folio/console/tiptap/render_nodes_json_component.rb` | **Unchanged.** See §4.2. |
| `smilemusic/app/services/publisher/tiptap_preview_context.rb` (new) | `mint(placement:, attribute_name:)` and `resolve(token:)` API. Stash + read `Rails.cache`. Cache entries: `{ placement_type, placement_id, attribute_name, user_id, site_id }`. TTL e.g. 4 hours sliding. |
| `smilemusic/config/initializers/folio_tiptap.rb` (new) | Register `Folio::Tiptap.config.preview_context_resolver = ->(controller, token) { Publisher::TiptapPreviewContext.resolve_into!(controller, token) }`. The resolver instantiates `Publisher::ListArticlesPicker`, calls `precompute_divider!`, and assigns it to `controller.instance_variable_set(:@list_articles_picker, picker)` (or exposes via a setter — see §4.3). |
| Host form view (e.g. `smilemusic/app/views/console/publisher/list/.../_form.html.slim`) | When rendering the input, mint a token: `f.input :tiptap_content, as: :tiptap, preview_context_token: Publisher::TiptapPreviewContext.mint(placement: @list, attribute_name: :tiptap_content)`. |
| `smilemusic/app/models/concerns/publisher/tiptap_node_component_with_list_articles.rb` | Drop the `return if console_preview?` early-out in `before_render` so the picker (when present in preview) loads articles. Adjust `render?` to return true when `@articles.present?` or when in preview without a picker (fall back to today's placeholder). Template branches on `@articles.present?` between real cards and the placeholder. |

### 4.2 Why `RenderNodesJsonComponent` is unchanged

The current preview path sets `tiptap_content_information[:record] = node` (the `Folio::Tiptap::Node` itself, not the placement). At first glance it seemed the placement should replace `node` there. It does not need to.

The host node concern reads the placement only through `controller.list_articles_picker`:

```ruby
@articles = controller.list_articles_picker&.pick(...)         # before_render
controller.list_articles_picker&.record                         # list
controller.list_articles_picker&.pagy                           # current_pagy
```

The picker carries the record. Once Approach A attaches the picker to the TiptapController instance, the node component renders identically to production without any change to `tiptap_content_information`. Other consumers of `tiptap_content_information[:record]` (e.g. `FolioTiptapNodeComponent#validate_node_type!`) already accept the node-as-record in preview today; behavior is unchanged for them.

A short audit before implementation: `grep -rn "tiptap_content_information\[:record\]\|@tiptap_content_information\[:record\]"` across both repos to confirm no other host concern depends on the placement being in that slot during preview. Today's preview already passes the node, so any code that worked yesterday will still work.

### 4.3 Exposing the picker on the controller

`Publisher::ListArticlesProvider` already defines `list_articles_picker` as an instance reader of `@list_articles_picker`. The resolver can either:
- include the concern into `TiptapController` from the host (still violates "host-app extension only" rule in spirit since it includes host code into a Folio controller); or
- set the instance variable directly via `controller.instance_variable_set(:@list_articles_picker, picker)` and rely on a `respond_to?` check at the call site in the node concern.

The second is cleaner. The node concern already uses `controller.list_articles_picker&.pick(...)` — it would become `controller.try(:list_articles_picker)&.pick(...)` to handle the case where the controller doesn't expose the method. Or the resolver can `controller.singleton_class.attr_reader :list_articles_picker` on first use. Implementation detail; either works.

### 4.4 Token lifecycle and TTL

- Token format: UUID v4 or `SecureRandom.urlsafe_base64(24)`.
- Cache key: `"tiptap_preview_context:#{token}"`.
- Cache value: `{ placement_type:, placement_id:, attribute_name:, user_id:, site_id:, created_at: }`.
- TTL: 4 hours sliding (`expires_in: 4.hours`, refreshed on every read). Editing sessions longer than 4 hours of inactivity lose preview fidelity and fall back to placeholders — acceptable.
- Eviction: rely on cache backend. No explicit cleanup needed.
- Cross-user safety: resolver checks `cached[:user_id] == Folio::Current.user.id` and `cached[:site_id] == Folio::Current.site.id`. A leaked token does not grant cross-user access.

### 4.5 Failure modes (Approach A)

| Case | Behavior |
|---|---|
| Token missing in request (e.g. host didn't wire it) | Resolver not called; render proceeds as today (placeholder via `console_preview?` short-circuit). No regression. |
| Token present but expired/evicted | Resolver returns nil; controller has no picker; node falls back to placeholder. Silent and benign. |
| Token present, user/site mismatch | Resolver refuses (authorization failure); falls back to placeholder. |
| Resolver raises | TiptapController error response → editor shows the node as failed. Should be caught and downgraded to placeholder. |
| Cache backend unavailable | Same as expired token: placeholder fallback. |
| Multiple render_nodes calls per editing session | Each lookup hits the cache. With Memcached/Redis backends this is sub-ms. Acceptable. |

### 4.6 Estimated effort

Rough estimate (not committed):
- Folio changes: 1 input option, ~30 lines of JS, ~20 lines of controller hook, config slot. **~0.5 day.**
- Folio tests: render_nodes with/without token, resolver invocation, resolver-raises path. **~0.5 day.**
- Smilemusic service + initializer + form wiring: **~0.5 day.**
- Smilemusic concern adjustment + tests across affected node components (10+ files include `TiptapNodeComponentWithListArticles`): **~1 day.**
- Manual editor QA across at least: Homepage list, Category list, Author list, new-record case, paste case. **~0.5 day.**

**Total: ~3 days** with no surprises. Add buffer for QA discoveries.

## 5. Decision Required from the Project Leader

**The single question that determines feasibility:** does adding an *opaque* `preview_context_token` option to `TiptapInput` violate the rule "input must remain ignorant of the record beyond what it does today"?

Arguments for accepting it:
- The token is record-agnostic from the input's perspective. The input does not interpret it. Folio's TiptapController does not interpret it. Only host code resolves it.
- It's the minimum extension that lets host code participate in render_nodes without coupling Folio to records.
- It scales to multi-tab/multi-record cases that Approach B fails on.

Arguments against:
- The token IS a side-channel for record context. Opaqueness is architectural framing, not isolation. A strict reading of "input is purely an editor mount point" precludes any new input option of any semantics.
- Future host needs may grow this surface (more tokens, more hooks). Slippery slope.

If accepted → proceed with Approach A. Effort estimate above.
If rejected → fall back to Approach B (document the tab-collision failure mode explicitly and decide if it's tolerable) or invest in Approach C (significantly more JS work and longer-term maintenance).
If neither acceptable → keep the current placeholder. The cost of preserving the rules strictly may exceed the benefit of real-article preview.

## 6. Out of Scope

- Generalizing to other record-dependent node types beyond list-articles. The mechanism is generic by design, but only list-article nodes have a concrete need today. Other consumers can opt in later.
- Editor preview for nodes that need to render across multiple records (cross-list, aggregations). Not requested.
- Replacing the cache backend with a database-backed token store. Cache is sufficient given the TTL semantics.
- Pagination interaction in preview (the `pagy` exposed by the picker is informational in preview; not used for navigation).

## 7. Next Steps

1. Share this document with the project leader.
2. Get a yes/no on §5.
3. If yes → invoke the writing-plans skill to produce a step-by-step implementation plan.
4. If no → either accept Approach B's trade-offs or close the feature and keep the placeholder.
