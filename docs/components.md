# Components

This chapter describes the component-based architecture of the Folio Rails Engine, focusing on UI development with ViewComponent, BEM methodology, Stimulus, and React integration.

---

## Introduction

Folio uses a modern, modular approach to UI development based on [ViewComponent](https://viewcomponent.org/). Components are organized for clarity, reusability, and maintainability, following BEM naming conventions and leveraging Stimulus for JavaScript behavior. React components can also be integrated for advanced interactivity.

Legacy Trailblazer Cells are still bundled for backwards compatibility but are scheduled for removal in the next major release.

---

## Creating Components (Recommended: Generator)

> **Best Practice:** Always use the provided Folio generator to create new components. This ensures all necessary files and structure are created correctly and consistently.

To generate a new component, run:

```sh
rails generate folio:component MyComponent
```

This command will:
- Create a new component class in `app/components/folio/my_component/my_component.rb`
- Generate a corresponding Slim template, SASS, and JS files as needed
- Set up the correct directory structure and naming conventions

For more details and advanced options, see the [Extending & Customization](extending.md) chapter.

---

## Directory Structure Example

```
app/components/folio/
  atom/                # Atomic content components
  console/             # Admin interface components
  ui/                  # Shared UI components
  ...
  my_component/
    my_component.rb    # Component class
    my_component.slim  # Slim template
    my_component.sass  # Component styles (BEM)
    my_component.js    # Optional JS (Stimulus/React)
```

---

## Best Practices

- **Naming:**
  - Use descriptive, purpose-indicating names
  - Suffix with `Component`
  - Namespace under `Folio::`
- **Organization:**
  - Group related components in subdirectories
  - Keep components focused and single-purpose
- **Styling:**
  - Use SASS with BEM methodology
  - Scope styles to the component
- **JavaScript Integration:**
  - Use Stimulus for behavior
  - Place JS in the same directory as the component
  - For React, use the `react/` directory and integrate via asset pipeline
- **Templates:**
  - Use Slim for templates
  - Keep templates minimal and focused
- **Documentation:**
  - Document public interface and usage
  - Include usage examples

---

## Advanced: Manual Customization

Manual creation or editing of component files is only recommended for advanced use cases. If you need to customize generated files, follow best practices for naming, organization, styling, and documentation.

---

## Component Relationships (Mermaid)

```mermaid
classDiagram
    ApplicationComponent <|-- AtomComponent
    ApplicationComponent <|-- ConsoleComponent
    ApplicationComponent <|-- UiComponent
    AtomComponent <|-- TextAtomComponent
    AtomComponent <|-- ImageAtomComponent
    ConsoleComponent <|-- CatalogueComponent
    ConsoleComponent <|-- TogglableFieldsComponent
    UiComponent <|-- DropzoneComponent
    UiComponent <|-- NestedFieldsComponent
```



## Advanced Component Topics

### Predefined Redactor Links
Folio allows editors to insert **pre-defined links** into any Redactor rich-text field.  
1. Create helper `Folio::Redactor::Link` records via the admin console (*Content → Redactor links*).  
2. Use the **RedactorInput** in your form – the toolbar will automatically show the link picker.

### Togglable Fields Component
`Folio::TogglableFieldsComponent` lets you reveal/hide parts of a form based on a checkbox or select value.
```slim
= render Folio::TogglableFieldsComponent.new(form: f) do |c|
  = c.toggler f.input :show_advanced, as: :boolean
  = c.fieldset do
    = f.input :advanced_option
```
The generator `rails generate folio:component TogglableFields` shows the full pattern.

### Remote Select Inputs
Use `Folio::RemoteSelectComponent` to load options via AJAX – ideal for large datasets.  
1. Generate the component if not present: `rails generate folio:component RemoteSelect`.  
2. Implement a JSON endpoint returning `{ id, text }` objects.  
3. In the form: `= f.input :author_id, as: :remote_select, url: authors_path(format: :json)`.

### React Integration
Projects that need React UI pieces should:
1. Install **React on Rails** or import-map-react.  
2. Place components in `app/javascript/react/` and register them.  
3. Mount via `= react_component "MyWidget", props` in a ViewComponent template.  
See the old wiki page *Working-with-react-in-folio* for a complete webpack example.

---

*Note: This is a simplified example. Actual component hierarchy may vary.*

## Navigation

- [← Back to Overview](overview.md)
- [← Back to Architecture](architecture.md)
- [Next: Atoms →](atoms.md)
- [Admin Console](admin.md) | [Files & Media](files.md)
- [Extending & Customization](extending.md) 

---

*For more details, see the individual chapters linked above. This components overview will be updated as the documentation evolves.* 