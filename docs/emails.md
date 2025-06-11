# Emails & Templates

This chapter explains how to work with mails in the Folio Rails Engine—creating mailers, managing email templates, and sending transactional emails.

---

## Introduction

Folio integrates tightly with **Action Mailer**. The engine ships with several production-ready mailers (e.g. Devise confirmations, AASM notifications, Lead notifications) and provides generators to help you scaffold new mailers with the correct structure.

---

## Generating a Mailer (Recommended)

> **Best Practice:** Use the Folio mailer generator to scaffold a new mailer together with its views and tests.

```sh
rails generate mailer MyApplication::Newsletter
```

This command will create, for example:

```
app/mailers/my_application/newsletter_mailer.rb
app/views/my_application/newsletter_mailer/
  newsletter.html.slim
  newsletter.text.erb
config/locales/my_application/newsletter_mailer.en.yml
```

The generator also prepares test and preview under `test/mailers/` and `test/mailers/previews/`.

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

Email templates can be defined by `Folio::EmailTemplate` records. They can be edited in the admin console (see *Admin → Email templates*). Each template has both HTML (`body_html`) and plain-text (`body_text`) parts.

When you need a new template type, define it in `data/email_templates_data.yml` and run `rake folio:email_templates:seed_all`.

```ruby
template_data = {
  LOCALE: locale,
  FOLIO_LEAD_ID: lead.id,
  FOLIO_LEAD_EMAIL: lead.email,
  FOLIO_LEAD_PHONE: lead.phone,
  FOLIO_LEAD_NOTE: lead.note,
  FOLIO_LEAD_CREATED_AT: lead.created_at ? l(lead.created_at, format: :short) : "",
  FOLIO_LEAD_NAME: lead.name,
  FOLIO_LEAD_URL: lead.url,
  FOLIO_LEAD_CONSOLE_URL: url_for([:console, lead, host: site.env_aware_domain, locale: ]),
}
opts = { reply_to: lead.email, site: }

email_template_mail(template_data, opts)
```

---

## Best Practices

- Keep plain-text versions up to date for better deliverability.

---

## Navigation

- [← Back to Overview](overview.md)
- [← Back to Forms](forms.md)
- [← Back to Admin Console](admin.md)
- [Next: Configuration →](configuration.md)

---

*For more details, see the individual chapters linked above. This emails & templates overview will be updated as the documentation evolves.* 
