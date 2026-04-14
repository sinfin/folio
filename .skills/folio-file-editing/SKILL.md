---
name: folio-file-editing
description: >-
  File editing hygiene for Folio and host apps: trailing whitespace removal,
  single trailing newline (POSIX EOF), no BOM, consistent line endings, and
  programmatic file writes. Apply whenever editing or generating any file —
  code, config, markdown, YAML, or templates.
---

# File editing conventions (Folio)

These rules apply to **every file you edit or create**, regardless of language.

## Trailing whitespace

Remove trailing whitespace from all lines. Never leave spaces or tabs after
the last visible character on a line.

```diff
- def foo   ⏎
+ def foo⏎
```

## Trailing newline (POSIX EOF)

Every file must end with **exactly one** newline character (`\n`). No missing
newline, no extra blank lines at the end.

```diff
- last_line|EOF       ← missing newline
+ last_line\n|EOF     ← correct

- last_line\n\n|EOF   ← extra blank line
+ last_line\n|EOF     ← correct
```

When writing files programmatically (rake tasks, generators, scripts), normalize
the ending before writing:

```ruby
content = content.sub(/\n*\z/, "\n")
File.write(path, content)
```

## Line endings

Use Unix line endings (`\n`, LF) everywhere. Never introduce `\r\n` (CRLF).

## No BOM

UTF-8 files must not include a byte order mark (BOM). If you detect `\xEF\xBB\xBF`
at the start of a file, remove it.

## Blank lines

- Use a single blank line to separate logical sections (methods, blocks, etc.)
- Never use more than one consecutive blank line
- No blank line at the very start of a file (after any frontmatter/magic comments)

## Indentation consistency

Preserve the existing indentation style of the file you're editing:
- Ruby, YAML, Slim, Sass: **2 spaces**
- JavaScript: **2 spaces** (StandardJS)
- Markdown: **2 spaces** for nested lists

Never mix tabs and spaces within a file.

## Verification

After editing, you can verify these conventions with:

```bash
# Trailing whitespace (should return nothing)
grep -rn ' $' <file>

# Missing trailing newline
test "$(tail -c1 <file>)" && echo "missing newline"

# CRLF line endings
grep -cP '\r$' <file>
```

Linters and formatters (rubocop, standardjs, slim-lint) enforce most of these
automatically — run them after every edit.
