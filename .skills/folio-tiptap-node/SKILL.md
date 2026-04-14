---
name: folio-tiptap-node
description: >-
  Creates and edits custom Tiptap block-editor nodes in Folio: the node model
  (Folio::Tiptap::Node subclass with tiptap_node structure), the view component
  for rendering, tiptap_config (icons, groups, paste), and i18n. Use when adding
  a new Tiptap node, editing node structure or rendering, wiring node groups/icons,
  or when the user mentions `rails g folio:tiptap:node`.
---

# Tiptap Node development (Folio)

## Prerequisites

- **Read [`docs/tiptap.md`](docs/tiptap.md)** — full tiptap architecture, attribute types, data structure, rendering flow, icons, groups, paste config, and CSS. Do not rely on memory alone.
- Follow **[`.skills/folio-view-component/SKILL.md`](../folio-view-component/SKILL.md)** for component conventions (BEM, Slim, testing rules, composition) — this skill only covers the **tiptap-node-specific** layer.

## Generator

**Always** use the generator for new nodes — do not create files by hand:

```sh
rails generate folio:tiptap:node contents/text
```

This creates (under the host app's namespace, e.g. `MyApp`):

| File | Purpose |
|------|---------|
| `app/models/my_app/tiptap/node/contents/text.rb` | Node model (`< Folio::Tiptap::Node`) |
| `app/components/my_app/tiptap/node/contents/text_component.rb` | View component |
| `app/components/my_app/tiptap/node/contents/text_component.slim` | Slim template |
| `test/components/my_app/tiptap/node/contents/text_component_test.rb` | Component test |
| `app/components/my_app/tiptap/node/base_component.rb` | Base component (created once, shared `initialize(node:, tiptap_content_information:)`) |
| `config/locales/tiptap/nodes.*.yml` | i18n entries |

## Node model

Define structure and config with `tiptap_node`. For attribute types, `tiptap_config` options (icons, groups, toolbar slots, paste), and placeholder/hint — see **`docs/tiptap.md`** (Custom Node Implementation).

```ruby
class MyApp::Tiptap::Node::Contents::Text < Folio::Tiptap::Node
  tiptap_node structure: {
    content: :rich_text,
  }, tiptap_config: {
    icon: "content_text",
    toolbar_slot: "after_layouts",
    group: "content",
  }
end
```

## View component

The generated component inherits from the base component. The template receives `@node` and `@tiptap_content_information` (keys documented in `docs/tiptap.md`).

BEM class follows the same rules as regular ViewComponents (see folio-view-component skill). Use `@tiptap_content_information[:editor_preview]` to conditionally simplify rendering inside the editor iframe.

## Testing

Tests subclass `Folio::Tiptap::NodeComponentTest` (extends `Folio::ComponentTest`). Follow the **folio-view-component** skill for testing rules — same principles apply: assert **rendered output**, one `render_inline` per test.

The `tiptap_content_information` helper and `create_test_tiptap_node` are provided by the test base class.

```ruby
class MyApp::Tiptap::Node::Contents::TextComponentTest < Folio::Tiptap::NodeComponentTest
  def test_render
    node = create_test_tiptap_node(MyApp::Tiptap::Node::Contents::Text)

    render_inline(MyApp::Tiptap::Node::Contents::TextComponent.new(node:, tiptap_content_information:))

    assert_selector(".m-tiptap-node-contents-text")
  end
end
```

## Wiring into the app

Register new nodes in the app's `default_tiptap_config` (see `docs/tiptap.md` for group and icon configuration):

```ruby
def self.default_tiptap_config
  ::Folio::Tiptap::Config.new(
    node_names: %w[
      MyApp::Tiptap::Node::Contents::Text
    ],
    node_groups: [
      { key: "content", title: { cs: "Obsah", en: "Content" },
        icon: "content", toolbar_slot: "after_layouts" },
    ],
  )
end
```

## i18n

The generator creates entries in `config/locales/tiptap/nodes.*.yml`. Add attribute translations under the node key; for `default:` / `hint:` procs, use nested keys like `title/default`.

## Quality gates

After edits: **`rubocop --autocorrect-all`** on Ruby, **`slim-lint`** on Slim, **`npx standard --fix`** on JS (see `AGENTS.md`).

## Reference

- Generator: `lib/generators/folio/tiptap/node/node_generator.rb`
- Node base class: `app/models/folio/tiptap/node.rb`
- Test base: `Folio::Tiptap::NodeComponentTest` in `test/test_helper_base.rb`
- Full tiptap docs: [`docs/tiptap.md`](docs/tiptap.md)
- ViewComponent conventions: [`.skills/folio-view-component/SKILL.md`](../folio-view-component/SKILL.md)
