# Forms

This chapter describes form building and validation in the Folio Rails Engine, highlighting the built-in custom inputs that ship with Folio and explaining how to add new ones.

---

## Introduction

Folio provides flexible tools for building and validating forms, both in the admin console and in public-facing features. A set of **custom Simple Form inputs** ships with the engine to handle common use-cases (e.g., rich-text editors, tag selectors, phone numbers).

---

## Built-in Custom Inputs

The engine includes the following input classes (see `app/inputs/`):

| Input class | Purpose |
|-------------|---------|
| `RedactorInput` | Rich-text editor using Redactor |
| `AdvancedRedactorInput` | Rich-text editor with extended toolbar |
| `EmailRedactorInput` | Redactor configured for email templates |
| `TagsInput` | Tag selector with autocomplete |
| `UrlJsonInput` | Array of links stored as JSON |
| `DateRangeInput` | Two-field date range picker |
| `PhoneInput` | Phone number input with formatting |

You can use these inputs directly in your `simple_form_for` blocks:

```slim
= f.input :content, as: :redactor
= f.input :tags,    as: :tags
```

---

## Adding Custom Inputs

Folio does **not** currently provide a generator for new inputs. To add a custom input:

1. Create a new class in `app/inputs/`, inheriting from `SimpleForm::Inputs::Base` or another existing input.
2. Implement the `input` method and any helpers.
3. Add related JavaScript or CSS if needed.
4. Document usage in your project.

You can copy one of the built-in inputs as a starting point.

---

## Form Integration in the Admin Console

- Admin forms are built with Rails helpers and the custom inputs above.
- Model validations ensure data integrity; additional validation logic can be placed in form objects or service layers.
- For complex workflows you can create **form objects** (POROs) that encapsulate validation and persistence logic.

---

## Best Practices

- Reuse and adapt the built-in inputs where possible.
- Keep validation logic in the model or a dedicated form object.
- Use namespaced CSS/JS for custom inputs to avoid conflicts.
- Document any custom input's expected data format.

---

## Navigation

- [← Back to Overview](overview.md)
- [← Back to Files & Media](files.md)
- [← Back to Admin Console](admin.md)
- [Next: Emails & Templates →](emails.md)

---

*For more details, see the individual chapters linked above. This forms overview will be updated as the documentation evolves.* 