# Folio Roadmap

This document collects proposed roadmap themes for Folio as an open-source Rails CMS engine.
It is a planning draft intended to support discussion and prioritization, not a delivery commitment.

## Planning Principles

- Prefer engine-level contracts over one-off rewrites.
- Keep the default path simple for small projects.
- Support multiple infrastructure models where justified.
- Treat generators, documentation, tests, and automation as part of the product surface.
- Reduce legacy surface area in stages, with clear migration paths.
- Optimize for both human contributors and AI-assisted workflows.

## Now

The "Now" horizon is split into foundational tracks and migration tracks.
Foundational tracks define the contracts and platform direction that later migrations should build on.
Migration tracks reduce the current legacy surface without losing delivery focus.

### Foundational Tracks

#### 1. Pluggable Image Transformation Pipeline

**Problem**

Dragonfly-based thumbnail generation creates operational and architectural pain:

- background thumbnail jobs are fragile and add queue pressure
- storage, URL generation, and processing orchestration are tightly coupled
- cache behavior is hard to reason about
- different projects need different infrastructure models

**Target Outcome**

Introduce a provider-based image transformation layer with a stable Folio contract and multiple backend implementations.

**Initial Scope**

- Define a canonical Folio thumbnail interface.
- Introduce stable application-facing thumbnail URLs.
- Internally use versioned or immutable result objects derived from source checksum + variant specification.
- Add a built-in compatibility provider for Sidekiq-based processing.
- Design a remote transformer API contract for external processing services.
- Make private files, signed access, crop variants, and invalidation part of the design from day one.

**Delivery Options**

- Built-in Sidekiq provider for small projects.
- Remote transformer service running on Kubernetes, either per app or per cluster.
- AWS-oriented provider using Thumbor and S3-compatible storage.
- Optional future serverless provider for low-traffic or bursty workloads.

**Success Criteria**

- Folio no longer depends on Dragonfly thumbnail jobs as the only model.
- Projects can switch providers without changing view-level APIs.
- Thumbnail URLs remain stable at the application level.
- Processing failures and cache misses are observable and debuggable.

#### 2. Cache Architecture Refresh

**Problem**

The current `cache_key_base` approach is not sufficient for larger projects and does not provide a robust invalidation model across dimensions such as site, locale, session-sensitive rendering, and public/private variants.

**Target Outcome**

Move from a narrow cache key convention to a clearer cache architecture with explicit dimensions, invalidation rules, and debugging support.

**Initial Scope**

- Formalize cache dimensions: site, locale, user/session requirements, published state, content version, and other relevant axes.
- Replace or supersede `cache_key_base` with a better engine-level contract.
- Integrate with existing HTTP cache work and component session requirements.
- Add cache diagnostics and developer tooling so cache decisions are explainable.
- Validate the approach against a larger-project proof of concept.
- Use the existing exploratory branch `petr/has-folio-tiptap-and-cache` as an initial reference point, then clean up and extract the durable architectural direction from it.

**Success Criteria**

- Cache invalidation is predictable on large installs.
- Cache contracts are documented and testable.
- Developers can inspect why a response or component was cached or bypassed.

#### 3. Packwerk and Modular Folio Surface

**Problem**

Folio still behaves largely as one large engine surface.
That makes architectural boundaries harder to enforce, increases accidental coupling, and makes it difficult to enable only selected parts of the engine in a clean way.

**Target Outcome**

Introduce explicit package boundaries and a more modular Folio layout so projects can reason about dependencies and selectively adopt engine capabilities.

**Initial Scope**

- Use the existing cache proof of concept, currently explored in `petr/has-folio-tiptap-and-cache`, as one of the first validation areas for package boundaries.
- Introduce Packwerk in a way that provides architectural feedback without blocking all development immediately.
- Identify candidate packages such as caching, files/media, console UI, TipTap, users, newsletter features, and other separable engine areas.
- Define which parts of Folio should be independently switchable at the configuration level and which should remain core.
- Reduce implicit cross-package dependencies and document allowed dependency directions.

**Success Criteria**

- Architectural boundaries become visible and enforceable.
- Large projects can adopt only the Folio areas they need with less incidental coupling.
- New engine work happens inside clearer module boundaries instead of expanding a monolith.

#### 4. OSS Contributor Platform

**Problem**

Folio works today, but the open-source contributor experience is still too dependent on internal knowledge and manual setup steps.

**Target Outcome**

Make the repository easy to install, run, test, and change for any external Rails developer.

**Initial Scope**

- Standardize local entrypoints such as setup, dev, test, lint, and CI commands.
- Reduce or isolate secrets required for local development.
- Define and document the supported version matrix for Ruby, Rails, Node, and external tooling.
- Treat generators as public API and harden them with real smoke tests.
- Improve release metadata, docs consistency, and contributor-facing guidance.

**Success Criteria**

- A new contributor can boot the project from documented commands alone.
- Generator workflows are tested, not just documented.
- Documentation reflects the actual supported stack.

### Migration Tracks

#### 5. UI Modernization Phase 1

**Problem**

Folio still carries a large legacy UI surface across Cells, jQuery, and legacy React islands.
That slows down maintenance, increases onboarding cost, and keeps multiple frontend patterns alive at the same time.

**Target Outcome**

Make ViewComponent + Stimulus the default and preferred path for Folio UI.

**Initial Scope**

- Continue the staged migration from Cells to ViewComponents on the most-used engine surfaces.
- Replace jQuery-driven interactions with Stimulus controllers where practical.
- Identify legacy React islands that should be migrated to Stimulus rather than expanded.
- Stop growing the legacy surface area through generators and new features.
- Publish a migration tracker so the remaining legacy footprint is visible.

**Success Criteria**

- New engine UI work does not introduce additional Cells or jQuery.
- The highest-value admin and public components have ViewComponent-based replacements.
- Frontend interaction patterns become more uniform across the codebase.

## Next

### 6. Atom to TipTap Migration Program

**Problem**

Atoms and TipTap currently coexist, but there is no complete engine-level migration program covering authoring UX, content migration, coexistence rules, and project guidance.

**Target Outcome**

Provide a realistic path for teams that want to move from atom-heavy editing flows to TipTap-driven structured content.

**Scope**

- Define the target role of Atoms vs TipTap nodes in Folio.
- Prepare authoring UI and editor affordances needed for wider TipTap adoption.
- Write migration guidelines for teams and projects.
- Support coexistence during migration rather than forcing a big-bang rewrite.
- Add tooling for content migration where possible.

**Success Criteria**

- Teams understand when to use Atoms, when to use TipTap, and how to migrate.
- Folio can support mixed-mode projects during transition.
- New content modeling guidance is coherent and maintainable.

### 7. UI Modernization Phase 2

**Problem**

After the first modernization pass, some legacy frontend surface will still remain for edge cases, generators, and older admin workflows.

**Target Outcome**

Complete the shift to the modern engine UI stack and retire legacy defaults.

**Scope**

- Finish the Cells to ViewComponents migration where a compatible replacement exists.
- Remove remaining jQuery-heavy workflows from core engine paths.
- Reassess the role of the legacy React app and either shrink it further or replace it.
- Update generators so newly generated code always follows the modern stack.

**Success Criteria**

- Legacy UI technologies are no longer the default scaffolding path.
- The maintenance burden of multiple frontend stacks is materially reduced.

### 8. AI Agent Readiness

**Problem**

Folio already includes AI-oriented instructions, but host applications generated by Folio do not yet get a strong, deterministic, agent-friendly contract.

**Target Outcome**

Make Folio-generated projects easier to use with coding agents such as Codex, Cursor, and Claude Code.

**Scope**

- Generate a richer local `AGENTS.md` for installed apps instead of only pointing back to the gem source.
- Provide deterministic setup, lint, test, and build entrypoints.
- Expose generators, config keys, and environment expectations in a machine-friendly way where useful.
- Reduce ambiguity around which stack is authoritative in each part of the repository.

**Success Criteria**

- Agents can bootstrap work from local project instructions without manual discovery.
- Folio-generated apps are easier to navigate and modify safely.

## Later

### 9. Data Model Cleanup

**Problem**

Some engine areas still rely on older persistence conventions and compatibility code that complicate upgrades and long-term maintenance.

**Target Outcome**

Reduce legacy persistence patterns and simplify the internal model layer.

**Scope**

- Replace remaining YAML `serialize` usage with more modern typed or JSON-based approaches where appropriate.
- Continue removing transitional compatibility branches once replacement paths are established.
- Document deprecation timelines for internal contracts that should disappear in the next major version.

### 10. Deployment Model Portfolio

**Problem**

Different Folio projects have very different scale and infrastructure requirements.
A single mandatory operations model is not a good fit.

**Target Outcome**

Support multiple validated deployment models without forcing the same trade-offs on every installation.

**Candidate Models**

- Simple in-app processing for small projects.
- Shared or dedicated transformer service for Kubernetes-based stacks.
- AWS-native image pipeline for teams that prefer cloud-managed primitives.

**Goal**

Keep the Folio developer-facing contract stable while making infrastructure a deployment choice instead of an engine constraint.

## Cross-Cutting Questions

- Which parts of the current engine are true public API and need compatibility guarantees?
- Which migrations should be automated, and which should remain guided/manual?
- Where do we want strict defaults, and where do we want provider-based extensibility?
- Which large reference projects should be used to validate the roadmap decisions before declaring them as engine direction?
