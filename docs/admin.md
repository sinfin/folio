# Admin Console

This chapter describes the Folio admin console, focusing on how to scaffold and customize admin resources using generators, manage user roles, and support multi-site administration.

---

## Introduction

The Folio admin console provides a modern, extensible interface for managing content, users, files, and site settings. It is designed for rapid development and customization, with a strong emphasis on generator-based workflows.

---

## Scaffolding Admin Resources (Recommended: Generator)

> **Best Practice:** Always use the provided Folio generators to scaffold new admin resources. This ensures all necessary files, controllers, views, and configuration are created correctly and consistently.

To scaffold a new admin resource, run:

```sh
rails generate folio:console:scaffold Article
```

This command will:
- Generate a controller, views, and routes for the new resource in the admin console
- Set up forms, index, and show pages using ViewComponents
- Register the resource for use in the admin sidebar

For more details and advanced options, see the [Extending & Customization](extending.md) chapter.

---

## User Roles and Multi-site Support

- **User Roles:**
  - The admin console supports multiple user roles (e.g., superadmin, editor, etc.)
  - Permissions are managed via the `Folio::Ability` class and can be extended as needed
- **Multi-site:**
  - Folio supports managing multiple sites from a single admin console
  - Users can be linked to one or more sites via `SiteUserLink`

---

## Best Practices for Extending the Admin Console

- Use generators for all new resources and major customizations
- Group related admin components and controllers logically
- Use ViewComponent for custom admin UI elements
- Document customizations and keep the admin interface consistent

---

## Advanced: Manual Customization

Manual editing of admin console files is only recommended for advanced use cases. If you need to customize generated files, follow best practices for organization, security, and documentation.

---

## Advanced Console Features

### CSV Export
Enable CSV export in any console controller by adding a `collection_csv` route and a `csv_attributes` method on your model.

### Nested Resources
Generate nested resources under a parent:
```sh
rails generate folio:console:scaffold Comment --through Article
```
This adds routes `/console/articles/:article_id/comments` and breadcrumbs.

### Multi-site Administration (Details)
- Each user can belong to multiple sites via `Folio::SiteUserLink`.
- `Folio::Current.site` is set based on the domain

### Abilities & Authorization
Folio uses `Folio::Ability` (CanCanCan-style) to define user permissions.

- Each site/user relationship is stored in `Folio::SiteUserLink` with a `role` column.
- `Folio::Ability#ability_rules` can be overridden via `app/overrides/` to add custom rules.
- Use `can_now?(:action, object)` to test permissions in controllers or views.
- Console controllers honour these abilities automatically.

Example override:
```ruby
# app/overrides/folio/ability.rb
Folio::Ability.class_eval do
  def ability_rules
    if user.superadmin?
      can :do_anything, :all
    end

    folio_console_rules
    sidekiq_rules
    app_rules
  end
end

---

## Navigation

- [← Back to Overview](overview.md)
- [← Back to Atoms (CMS Blocks)](atoms.md)
- [← Back to Components](components.md)
- [Next: Files & Media →](files.md)
- [Extending & Customization](extending.md)

---

*For more details, see the individual chapters linked above. This admin console overview will be updated as the documentation evolves.* 
