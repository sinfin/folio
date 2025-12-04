# Agent Instructions

## AGENTS.md File Resolution

AGENTS.md files can be placed at the project root or in subdirectories. When multiple files exist, traverse up from the edited file's directory to the root, collecting all AGENTS.md files. Files closer to the edited file take precedence over files further away.

**Example:** Files in the `tiptap/` directory use `tiptap/AGENTS.md` which overrides the JavaScript formatting/linting instructions from the root `AGENTS.md` (using eslint/prettier instead of standardjs).

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

- Use TDD (write tests first)
- Use early returns to reduce nesting
- Keep methods focused and under ~20 lines
- Use namespaces for entire functionality (all related models, controllers, components together)

## View Components

- Always use the component generator: `rails generate folio:component blog/post` generates `MyApp::Blog::PostComponent`
- Use BEM methodology for CSS class names
  - Block (B) is generated from component class name - takes first letter (lowercase) of top-level namespace + rest of namespace path in kebab-case
    - Example: `MyApp::Blog::PostComponent` → Block is `"m-blog-post"`
    - Special case: `Folio::Console::` → `f-c`
  - Elements (E) and Modifiers (M) follow standard BEM: `__element` and `--modifier`
    - Example: `m-blog-post__button` (element), `m-blog-post__button--active` (modifier)
- Stimulus: Use `stimulus_controller("controller-name", values: {...}, action: {...}, classes: [...])` helper for JavaScript behavior
- Testing: Always test against rendered content, not instance methods
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
