# Shared select components plan

Status: planned. This document describes the intended implementation and
migration; the proposed components and asset entry points do not exist yet.

## Decision and scope

Consolidate Folio's enhanced selects around Tom Select behind a Folio-owned
interface. Implement `Folio::SelectComponent` in the shared `Folio::` namespace,
inheriting from `Folio::ApplicationComponent`, so Console and public host
applications can use the same component.

Keep ordered selection in a separate `Folio::Select::OrderedMultiselectComponent`
with Stimulus. It will use the regular select to add items and own the selected
list, ordering, and form serialization. Ordinary multiselect and tags belong in
`Folio::SelectComponent`. The ordered component lives under
`app/components/folio/select/`; the shared component stays at the top level of
`Folio::`. This grouping does not require a separate Packwerk pack.

Use the existing `vd/stimulus-ordered-multiselect` branch as a reference for
future functionality. Implementing or merging that branch is a later task and
does not block the shared select. This plan does not prescribe carrying over
its implementation.

Defer creating a separate `piq` library. Reconsider it if measured integration
work establishes an unacceptable limitation, such as a much smaller mandatory
frontend bundle budget or a requirement for React to own the internal markup.
Avoid building a general interchangeable-backend framework in anticipation of
that possibility; keep Tom Select usage behind a small, explicit interface.

## Existing integration points

| Area | Current implementation | Migration responsibility |
| --- | --- | --- |
| Ordinary multiselect | [Tom Select wrapper](../../app/assets/javascripts/folio/input/multiselect.js) | Preserve initial values and collection-order behavior where intended. |
| Searchable local collections | [Select2 wrapper](../../app/assets/javascripts/folio/input/collection_filterable.js) | Preserve grouped options, clearing, and change notifications. |
| Remote collections | [Select2 wrapper](../../app/assets/javascripts/folio/input/collection_remote_select.js) | Preserve pagination, initial selections, images, metadata, and dependent filters. |
| Tags | [Stimulus input](../../app/assets/javascripts/folio/input/tags.js) and [legacy cell](../../app/cells/folio/console/tagsinput/tagsinput.js) using Selectize | Preserve delimiters, suggestions, creation, and submission formats. |
| React selects and tags | [Shared React select](../../react/src/components/Select/index.js) | Replace the underlying select while preserving parent-controlled values and callers' metadata. |
| Ordered associations | [React application](../../react/src/containers/OrderedMultiselectApp/index.js) and [serializer](../../react/src/containers/OrderedMultiselectApp/Serialized/index.js) | Migrate later, preserving join-record identity and all serialization modes. |
| Form integration | [SimpleForm collection override](../../app/overrides/lib/simple_form/inputs/collection_select_input_override.rb) and [tags input](../../app/inputs/tags_input.rb) | Adapt existing form options to the shared component. |
| Server responses | [Autocomplete controller](../../app/controllers/folio/console/api/autocompletes_controller.rb) | Map existing response formats through adapters during migration. |

Also inventory link pickers, editor integrations, new-record modals, atom
settings, and code that calls a library instance directly. A migration is not
complete until these callers use the shared interface or are explicitly retired.

## Architecture

| Layer | Responsibilities |
| --- | --- |
| Shared JavaScript adapter | Tom Select initialization, option/value updates, callbacks, focus, reset, and destruction. Usable without Stimulus or React. |
| `Folio::SelectComponent` and its Stimulus controller | Server-rendered form markup, component configuration, lifecycle, and DOM events. |
| React adapter | Controlled values, callbacks, option changes, refs, and lifecycle around the same JavaScript implementation. |
| Data adapters | Normalize response shapes, supply request context, and map selected values back to each caller's existing format. |
| Future ordered multiselect | Own the selected list, reordering, removal, association metadata, and serialization; consume selection events from the regular select. |

Keep the shared component independent of Console translations, controllers,
stylesheets, routes, and globals. Console integrations supply their own endpoint
configuration and application behavior. Public applications supply their own
authorized data endpoints; using the component must not require access to
Console APIs.

Follow Folio's global JavaScript namespace convention for asset-pipeline code.
Keep reusable library integration in `window.Folio.Select` and component
lifecycle in its colocated Stimulus controller. The React adapter must reuse the
same implementation without adding React to public frontend assets or loading
a second copy of Tom Select on a page.

Generate new components with the Folio component generator when implementation
starts. Follow the existing ViewComponent, Stimulus, SimpleForm, styling, and
testing skills.

## Shared select behavior

### Modes and option identity

Support native single select, enhanced single select, searchable local
collections, ordinary multiselect, tags, and remote collections. A native mode
can leave a plain select unenhanced when JavaScript provides no useful behavior.

Define one normalized option shape, provisionally `{ value, label, data }`, with
optional grouping and disabled state. Preserve caller metadata such as record
type, numeric ID, image URL, and link attributes. Use a stable selection key;
do not assume every key is an integer or discard type information from existing
compound keys. Preserve valid values such as `0`.

Keep selected option data independently of the currently loaded result page.
Existing selections must retain their labels when a search changes, a request
fails, or the selected record is absent from the first page.

Make selection-order behavior explicit. Preserve collection order where the
current ordinary multiselect requires it. The ordered component will own
user-defined ordering separately.

Support grouped collections, placeholders, clearing, maximum selection counts,
disabled options, custom option content, and localized status text. Render
labels safely; custom rendering must have an explicit text/markup contract.

### Remote data and creation

Provide a loader contract accepting the query, explicit pagination state,
request context, and cancellation signal. Normalize results to options and
the next page or cursor. Keep server pagination metadata authoritative rather
than inferring the next page from the number of displayed options.

- Debounce searches and cancel or ignore obsolete responses.
- Preserve server ranking when remote filtering owns search relevance.
- Support configurable minimum query length, including Folio's existing
  behavior of allowing an empty query while rejecting short nonempty queries.
- Include selected-item exclusions and dependent-field filters where needed.
- Invalidate relevant cached results when those dependencies change.
- Distinguish loading, no results, and request failure without losing selection.
- Support creation together with remote pagination, including duplicate
  handling, pasted tags, and failed asynchronous creation.

Keep endpoint-specific request parameters and response mapping in data
adapters. Initially support the existing APIs without requiring a simultaneous
server rewrite. Rails integrations should use `Folio.Api` for transport.

Distinguish creating a tag value from persisting a database record. Expose a
creation callback; the application owns persistence, authorization, validation,
and error messages.

### Forms, events, and lifecycle

Preserve names, values, labels, required/disabled state, error presentation, and
native form submission semantics. Cover form reset, clearing all selections,
and selected values restored after validation errors.

Define the shared API for getting/setting values, updating options and request
context, clearing, focusing, resetting, and destroying. Define when programmatic
updates are silent. User changes must notify the owning form once through
standard bubbling events; keep legacy Folio event bridges only where existing
callers still need them.

The ordered parent should communicate with the select through public methods
and events, without querying its internal markup or taking ownership of its
Stimulus targets.

Initialize once per connected element. Clean up listeners, timers, requests,
plugin instances, and detached dropdowns on teardown. Verify reconnects,
Turbo navigation/cache restoration, replaced forms, nested fields, and modals.

React support means reliable parent-driven updates and lifecycle behavior
around an imperative widget. It does not promise JSX ownership of the internal
option markup. Account for the existing React 16 application and the separate
React 19 environment when choosing adapter APIs and peer requirements.

## Styling and accessibility

Use the `f-select` BEM block and a documented CSS-variable contract following
Folio's naming conventions. Keep structural styles separate from visual themes.
Provide a minimal unthemed presentation and an optional Bootstrap theme, with
host customization through CSS variables and scoped classes.

Keep Console-specific appearance outside the shared default theme. Consumers
should not need selectors targeting Tom Select internals; contain necessary
upstream overrides in the adapter's stylesheet.

Accessibility is part of every enhanced mode. Verify keyboard navigation,
selection and removal, focus visibility, accessible names, validation messages,
disabled states, composition input, and screen-reader announcements. Check
dropdown placement and focus inside modals. The future ordered component also
needs an accessible alternative to pointer-only drag reordering.

## Asset packaging and loading

Expose standalone logical assets, provisionally `folio/select.js` and
`folio/select.css`, through `app/assets/config/folio_manifest.js`:

```js
//= link folio/select.js
//= link folio/select.css
```

A Sprockets host can continue using this in its own asset manifest:

```js
//= link folio_manifest.js
```

These links make the assets precompilation targets. They do not include their
contents in the host application bundle or download them on every page. Use the
host's normal asset helpers so fingerprints and the configured asset host are
resolved through the normal deployment pipeline.

Support both host choices:

1. Include the select in the application's existing JavaScript and stylesheet
   bundles when usage is common or simpler loading is preferred.
2. Include standalone assets on pages that need the component, using stylesheet
   and deferred script tags in the initial HTML.

For standalone loading, the intended helper usage is:

```erb
<%= stylesheet_link_tag "folio/select" %>
<%= javascript_include_tag "folio/select", defer: true %>
```

Document shared runtime prerequisites and script order. Ensure either loading
path initializes each select once, and avoid including the library in both the
application bundle and a standalone tag on the same page. Separate the future
ordered component's assets and sorting dependency from ordinary select assets.

Load visible controls' CSS before first paint and request their JavaScript from
the initial HTML. Match the initial control's dimensions and selected label to
the enhanced presentation. Preserve a usable native fallback where possible.
Interaction-triggered loading is appropriate for controls inside unopened
modals, provided loading and failure states are handled.

A separate asset does not imply late loading. Enhancement can still cause a
visible transition with either packaging choice. Test cold-cache loading under
network and CPU throttling; avoid promising an invisible upgrade before this
has been measured. A loading shell, if needed, must reserve space and recover
when initialization fails.

### Measured size baseline

Planning measurements used Tom Select 2.6.2, consistent Terser minification,
gzip level 9, and Brotli quality 11. Sizes are decimal kB. The repository's
existing vendored JavaScript identifies itself as version 2.3.1; choose and pin
the tested version explicitly during implementation.

| JavaScript configuration | Minified | Gzip | Brotli |
| --- | ---: | ---: | ---: |
| Base | 42.2 kB | 14.6 kB | 13.0 kB |
| Base + clear button + remote pagination | 45.0 kB | 15.5 kB | 13.8 kB |
| Proposed Folio plugin set | 47.9 kB | 16.3 kB | 14.5 kB |
| All plugins | 52.2 kB | 17.4 kB | 15.5 kB |

The proposed plugin set is `clear_button`, `virtual_scroll`, `dropdown_input`,
`remove_button`, `caret_position`, and `input_autogrow`. Confirm the set against
actual interaction requirements. Here, `virtual_scroll` supplies incremental
remote pagination; it does not establish DOM windowing for huge local lists.

The shipped default theme adds approximately 2.4 kB gzip, and the Bootstrap 5
theme approximately 3.3 kB gzip, excluding Bootstrap itself. The JavaScript
figures include bundled library dependencies but exclude the future Folio
adapter, shared Stimulus runtime, React adapter, and ordered component.

These are planning measurements, not a production asset-size guarantee or a
browser performance benchmark. Measure the actual compiled assets and the
incremental cost within representative host bundles before rollout.

Most weight is in the core. Start with one documented plugin build unless
measurement justifies separate public and Console builds. Removing a few
plugins saves much less than avoiding the asset entirely on pages without
enhanced selects. Produce any custom build through upstream's supported build
or module-entry workflow, with a pinned version and reproducible command.

## Future ordered multiselect

Implement this after the shared select contract is proven. The component owns
the selected records and embeds a regular single select for adding another
record. It must preserve the existing capabilities:

- Ordered selected-item rendering, removal, and optional sorting.
- Remote or local grouped collections and exclusion of selected options.
- Maximum item counts and dependent atom-setting updates.
- Scalar, array, and nested-association submission formats.
- Separate join-record IDs and selected-record values.
- Position fields only where sorting is part of the association contract.
- `_destroy` fields for persisted removed associations and preservation of
  join-record identity when a removed record is re-added.
- Restoration of current and removed selections after validation failure.

Treat inline record creation, renaming, deletion, and usage information from
the feature branch as a subsequent feature set. Keep that domain behavior in
Folio/application integrations. The generic select may expose rendering and
action hooks without owning database CRUD or deletion policy.

Decide the presentation of management actions separately. Editing inside a
dropdown needs deliberate keyboard, focus, and screen-reader behavior. Prefer
documented extension points and explicit action UI over overriding internal
focus or close methods of the underlying library.

## Implementation phases

### 1. Confirm the contract and difficult examples

- Inventory current select callers, direct library access, events, response
  shapes, and submission formats.
- Define the public adapter methods, option identity, ordering policy, loader
  contract, and theme variables.
- Establish examples for a public remote filter, a grouped local select,
  creatable remote tags, and a parent-controlled React select.
- Exercise modal placement, initial remote values, and dependent query changes.
- Pin Tom Select and verify the smallest useful plugin set and compiled sizes.

Completion: these examples work through the proposed shared interface, with
any concrete Tom Select limitations recorded before broad migration.

### 2. Implement the shared component and packaging

- Generate `Folio::SelectComponent` and add the shared JavaScript adapter,
  Stimulus lifecycle, structural styles, and optional Bootstrap theme.
- Implement native, local, multiple, tags, and remote modes.
- Add SimpleForm integration while preserving the existing calling conventions
  where practical.
- Export standalone assets and document bundled and page-specific inclusion.
- Prove usage in a public dummy-app page without Console assets.

Completion: the component is usable in Console and public layouts, and both
asset-loading paths are verified in production-style precompilation.

### 3. Migrate existing ordinary selects

- Move existing Tom Select multiselects, Select2 collections, and Selectize tags
  onto the shared implementation in focused steps.
- Migrate link pickers, editor integrations, modal-created options, atom
  settings, and other direct library callers.
- Add the React adapter and migrate shared React select/tag callers.
- Preserve existing endpoint contracts with adapters during the transition.
- Verify remote creation and pagination work together.

Completion: ordinary enhanced selects use one implementation, and necessary
compatibility bridges are documented rather than spread through consumers.

### 4. Implement the ordered component as a separate task

- Use the future feature requirements above and the existing branch as input.
- Generate `Folio::Select::OrderedMultiselectComponent` in the select namespace.
- Implement the ordered list, accessible sorting, and serialization through
  the proven shared select API.
- Migrate current ordered React callers with submission-format parity.
- Schedule record-management features independently of basic ordered selection.

Completion: ordered selection uses the same generic picker and preserves
association behavior without adding its dependencies to ordinary selects.

### 5. Remove obsolete integrations

- Remove Select2, Selectize, react-select, and related adapters/styles only when
  their callers have migrated.
- Remove legacy event bridges and library-specific endpoints when no supported
  callers remain, documenting host-facing compatibility changes.
- Audit shared dependencies before removal: sorting or React packages may
  still serve unrelated features.
- Rebuild generated assets through the repository's normal build workflow.
- Publish usage, migration, theming, asset-loading, and accessibility guidance.

## Verification and acceptance

Use behavior-facing component, JavaScript, and integration/system tests. For
larger functionality, add a focused failing test before implementation. Avoid
tests that assert implementation source strings or merely repeat static markup.

Verify selection and clearing, form submission/reset, disabled and required
states, grouping, initial remote values, pagination, response races, dependency
changes, creation failure, duplicate handling, and lifecycle cleanup. Cover
keyboard/composition input and perform screen-reader checks for the primary
modes. Verify React parent updates without losing focus or emitting callback
loops.

For the future ordered component, cover removing and restoring persisted joins,
ordering, all submission modes, and validation rerenders. Verify these through
submitted values and user-visible behavior.

Check that public usage loads no Console or React assets, standalone files are
present after precompilation, and bundled usage does not load duplicate copies.
Measure cold-load presentation and compressed bundle sizes. Run the appropriate
formatters and linters for each implementation change.

## References

- [Folio component conventions](../components.md)
- [Folio JavaScript conventions](../../.skills/folio-javascript/SKILL.md)
- [Folio Stimulus conventions](../../.skills/folio-stimulus/SKILL.md)
- [Folio SimpleForm integration](../../.skills/folio-simple-form-inputs/SKILL.md)
- [Folio testing guidance](../../.skills/folio-testing/SKILL.md)
- [Tom Select configuration](https://tom-select.js.org/docs/)
- [Tom Select plugins and custom builds](https://tom-select.js.org/docs/plugins/)
- [Tom Select remote pagination](https://tom-select.js.org/plugins/virtual_scroll/)
- [Sprockets manifest links](https://github.com/rails/sprockets#link)
- [Deferred script behavior](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/script#defer)
