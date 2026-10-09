# Agent Instructions

## AGENTS.md File Resolution

AGENTS.md files can be placed at the project root or in subdirectories. When multiple files exist, traverse up from the edited file's directory to the root, collecting all AGENTS.md files. Files closer to the edited file take precedence over files further away.

**Example:** Files in the `tiptap/` directory use `tiptap/AGENTS.md` which overrides the JavaScript formatting/linting instructions from the root `AGENTS.md` (using eslint/prettier instead of standardjs).

## Skills (`.skills/`)

Structured agent workflows live in **`.skills/<name>/SKILL.md`** (YAML frontmatter: `name`, `description`, trigger-oriented wording).

When a task matches a skill’s description, **read that `SKILL.md` and follow it**. Host applications may use the same `.skills/` layout for their own workflows.

When the user corrects an agent about Folio conventions, check whether the
guidance belongs in an existing `.skills/*/SKILL.md` file. Prefer the relevant
skill when the correction applies to a specific workflow. Before editing a
skill, ask the user whether to update that specific skill with the correction.
If no existing skill fits, suggest updating this `AGENTS.md` or creating a new
`.skills/<name>/SKILL.md`.

| Skill | Triggers (examples) |
|-------|---------------------|
| **folio-view-component** | Build or change ViewComponents (generator, BEM, Slim/Sass, Stimulus data attrs, tests); frontend in `app/components` |
| **code-review** | Review current local branch changes or explicit diffs; findings-first feedback for code review prompts |
| **folio-pack** | Optional pack boundaries and namespaces; files under `packs/<name>`; route mappings to pack-owned controllers/components |
| **folio-rails-code-structure** | Ruby/Rails code structure: thin model/controller/concern entrypoints, focused classes under `lib/`, avoid helper-method clusters; excludes jobs |
| **folio-rails-models** | Rails/ActiveModel models: validations, virtual attributes, attachment/file placement validation targets, console required markers |
| **folio-file-placement** | Custom `Folio::FilePlacement` subclasses, placement naming, `has_one_placement`/`has_many_placements`, Console pickers, strong params, I18n, STI renames |
| **folio-testing** | Folio/host-app test strategy, behavior-facing assertions, component/JS behavior tests, stubs/mocks, factories/fixtures; `test/**`, `packs/**/test/**` |
| **folio-slim** | Slim template formatting: multi-line attributes, multiple `class` attrs, avoid inline Ruby, template length; `.slim` files |
| **folio-scss** | SCSS/Sass styling: BEM nesting with `&`, colocated component stylesheets, scoping, don't style child components; `.sass`/`.scss` files |
| **folio-javascript** | JavaScript conventions: ES6+, StandardJS, `Folio.Api`, flash events, debounce/throttle, DOM APIs; `.js` files |
| **folio-component-json-api** | `render_component_json` HTML-over-wire APIs: JSON body with string `data` (component HTML), `Folio.Api.apiGet`/`apiPost` and `response.data`, integration tests with `as: :json` |
| **folio-console** | Folio Console controllers/views, catalogue DSL, nested/through resources, scaffolded CRUD, route helpers, position controls, admin tests |
| **folio-embed-data** | `folio_embed_data`, `as: :embed`, canonical Folio embed JSON, replacing legacy embed fields, and embed validation, rendering, migration, or console forms |
| **folio-icons** | Add icons from Figma to `data/icons`, `currentColor` fills/strokes, `bin/icons`, sprite and `folio_icons.yaml`, restart server |
| **folio-stimulus** | Stimulus controllers: registration, StimulusHelper data attributes, values/targets/actions, `inline: true`; uses **folio-javascript** |
| **folio-simple-form-inputs** | SimpleForm inputs/extensions: `app/inputs`, overrides/prepends, `register_stimulus`, `input_controls`, `custom_html`, standalone input JS/Sass |
| **folio-tiptap-node** | Create or edit custom Tiptap block-editor nodes; `rails g folio:tiptap:node`; node structure, icons, groups, paste config; uses **folio-view-component** |
| **folio-view-component-migration-from-cells** | Replace Trailblazer `*Cell` with `*Component`; `cell(` → `render`; uses **folio-view-component** |
| **folio-file-editing** | File hygiene: trailing whitespace, single trailing newline, no BOM, LF line endings; applies to every file edit |
| **folio-stimulus-migration-from-legacy-js** | Migrate jQuery / `$(document).on` / legacy bundles to Stimulus + vanilla DOM; uses **folio-stimulus** |

## Code Formatting and Linting

After editing any code files, automatically format and lint them using the appropriate tools for that language.

### Bash/Shell
- Format: `shfmt -w <file_path>`
- Lint: `shellcheck <file_path>`

### Ruby/Ruby on Rails
- Format & Lint: `bundle exec rubocop --autocorrect-all <file_path>`
- Note: Guard automatically runs rubocop on Ruby files when they change. For manual runs, use the command above.
- When spanning method arguments across multiple lines, align arguments with the opening parenthesis

### JavaScript
- Format & Lint: `npx standard --fix <file_path>`
- Note: Guard automatically runs standardjs on JavaScript files when they change. For manual runs, use the command above.

### Slim
- Lint: `slim-lint <file_path>`
- Note: Guard automatically runs slimlint on Slim files when they change. For manual runs, use the command above.

## Rails Best Practices

- Use TDD for larger functionality: add or update the focused test first, run it to confirm it fails for the expected reason, implement the smallest change to pass it, then rerun the focused test and relevant verification.
- For simple refactors or single-method implementations, TDD is optional; use judgment and run focused verification appropriate to the risk and scope of the change.
- Use early returns to reduce nesting
- Keep methods focused and under ~20 lines
- Use namespaces for entire functionality (all related models, controllers, components together)

## Generators (IMPORTANT)

**Always use Rails/Folio generators** to create new files for components covered by generators. Never create these files manually.

This includes but is not limited to:
- **Migrations:** `rails generate migration AddFieldToTable`
- **Models:** `rails generate model ModelName`
- **Controllers:** `rails generate controller ControllerName`
- **View Components:** `rails generate folio:component namespace/name`
  - **Note:** For Folio components (in the `Folio::` namespace), use a leading slash: `rails generate folio:component /folio/console/ui/flag` generates `Folio::Console::Ui::FlagComponent`
- **Atoms:** `rails generate folio:atom namespace/atom_name`
- **Cells:** `rails generate folio:cell namespace/cell_name`
- **Console (admin) resources:** Check available Folio generators with `rails generate --help | grep folio`

Generators ensure:
- Correct file naming conventions and paths
- Proper namespacing and class inheritance
- Required boilerplate and structure
- Consistency across the codebase

## View Components

- Always use the component generator: `rails generate folio:component blog/post` generates `MyApp::Blog::PostComponent`
- Use BEM methodology for CSS class names
  - Block (B) is generated from component class name - takes first letter (lowercase) of top-level namespace + rest of namespace path in kebab-case
    - Example: `MyApp::Blog::PostComponent` → Block is `"m-blog-post"`
    - Special case: `Folio::Console::` → `f-c`
  - Elements (E) and Modifiers (M) follow standard BEM: `__element` and `--modifier`
    - Example: `m-blog-post__button` (element), `m-blog-post__button--active` (modifier)
- Stimulus: Use `stimulus_controller("controller-name", values: {...}, action: {...}, classes: [...])` helper for JavaScript behavior
- Testing: Follow `.skills/folio-testing/SKILL.md` for rendered-output assertions
  and one-render-per-test guidance.
- Ruby code:
  - Most ViewComponent instance methods can be private
  - Prefer ViewComponents over partials
  - Prefer ViewComponents over HTML-generating helpers
  - Prefer slots over passing markup as an argument
- See [docs/components.md](docs/components.md) for detailed component guidelines

## File Formatting Standards

When editing any file:
- Remove trailing whitespace from all lines
- Keep a single newline at the end of file (EOF)

## Git Commits

All commits must use semantic commit messages:

```
<type>(<scope>): <subject>

<body>
```

**Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

**Examples:**
- `feat(nested_fields): add sortable auto scroll`
- `chore(react): standardjs lint`
- `docs(tiptap): add early returns preference to AGENTS.md`

Scope is optional but recommended for clarity. Describe the final state/outcome, not the implementation steps. Keep the message concise and focused on what was achieved.
