# Emails & Templates

This chapter explains how to work with mails in the Folio Rails Engine—creating mailers, managing email templates, and sending transactional emails.

---

## Introduction

Folio integrates tightly with **Action Mailer**. The engine ships with several production-ready mailers (e.g. Devise confirmations, AASM notifications, Lead notifications) and provides generators to help you scaffold new mailers with the correct structure.

---

## Generating a Mailer (Recommended)

> **Best Practice:** Use the Folio mailer generator to scaffold a new mailer together with its views and tests.

```sh
rails generate folio:mailer Newsletter
```

This command will create, for example:

```
app/mailers/folio/newsletter_mailer.rb
app/views/folio/newsletter_mailer/
  newsletter.html.slim
  newsletter.text.erb
config/locales/folio/newsletter_mailer.en.yml
```

The generator also prepares test stubs under `test/mailers/` and `test/mailers/previews/`.

For advanced options, see the [Extending & Customization](extending.md) chapter.

---

## Built-in Mailers

The core engine includes:

| Mailer | Purpose |
|--------|---------|
| `Folio::DeviseMailer` | Overrides Devise emails (confirmation, reset password, etc.) |
| `Folio::AasmMailer` | Sends notifications when AASM state changes |
| `Folio::LeadMailer` | Sends notifications for contact/lead forms |

---

## Email Templates

Reusable email templates live under `app/views/folio/email_templates/` and are rendered via the `Folio::EmailTemplate` model. They can be edited in the admin console (see *Admin → Email templates*). Each template has both HTML Slim (`mail.html.slim`) and plain-text ERB (`mail.text.erb`) parts.

When you need a new template type, create a record in the console or via seed data and reference it from your mailer:

```ruby
template = Folio::EmailTemplate.find_by!(key: :newsletter)
mail to: user.email, subject: template.subject do |format|
  format.html { render inline: template.html_body }
  format.text { render inline: template.text_body }
end
```

---

## Best Practices

- Prefer the generator to create new mailers and keep a consistent structure.
- Store repeated layouts/content in `email_templates` rather than hard-coding.
- Keep plain-text versions up to date for better deliverability.
- Localise subjects and static strings through I18n YAML files.

---

## Navigation

- [← Back to Overview](overview.md)
- [← Back to Forms](forms.md)
- [← Back to Admin Console](admin.md)
- [Next: Configuration →](configuration.md)

---

*For more details, see the individual chapters linked above. This emails & templates overview will be updated as the documentation evolves.* 