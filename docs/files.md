# Files & Media

This chapter describes file and media management in the Folio Rails Engine, focusing on best practices and generator-based workflows for file placements, custom file types, and media handling.

---

## Introduction

Folio provides a robust system for managing files and media assets, including images, videos, documents, and more. File placements allow you to associate files with pages, atoms (CMS blocks), or other models, supporting flexible content structures.

---

## File Placements and Custom File Types (Recommended: Generator)

> **Best Practice:** Use Folio generators to create custom file placements or file types. This ensures all necessary models, associations, and configuration are set up correctly.

To generate a custom file placement, run:

```sh
rails generate folio:file_placement MyCustomPlacement
```

To generate a custom file type, run:

```sh
rails generate folio:file MyCustomFile
```

These commands will:
- Create the necessary models and associations
- Set up admin console integration for file management
- Register the new file type or placement for use in your project

For more details and advanced options, see the [Extending & Customization](extending.md) chapter.

---

## Overview of File Placements, Metadata, and Media Types

- **File Placements:**
  - Allow files to be attached to pages, atoms, or other models
  - Support single or multiple file associations
- **Metadata:**
  - Folio extracts and stores metadata for each file (e.g., image dimensions, video duration)
  - Metadata can be used for display, filtering, or processing
- **Media Types:**
  - Images, videos, audio, documents, and other file types are supported
  - Custom file types can be defined using generators

---

## Best Practices for Extending File Handling

- Use generators for all new file types and placements
- Keep file associations clear and well-documented
- Leverage metadata for advanced features (e.g., responsive images, previews)
- Use the admin console for file management whenever possible

---

## Advanced: Manual Customization

Manual editing of file or placement models is only recommended for advanced use cases. If you need to customize generated files, follow best practices for associations, validations, and documentation.

### Form Helpers for File Placements

**Single placement**
```slim
= simple_form_for @page do |f|
  = f.association :hero_image_placement, as: :file_placement, file_type: "Folio::File::Image"
```
**Multiple placement**
```slim
= f.association :gallery_placements, as: :file_placements, file_type: "Folio::File::Image"
```

### Audio / Video Media
- Supported subtitle languages configured via `config.folio_files_video_enabled_subtitle_languages` (default `[%w[cs]]`).
- Videos are transcoded via Active Storage variants; ensure **ffmpeg** is installed for tests.
- Use the `Folio::VideoPreviewComponent` to render a poster + controls.

### Image Metadata Extraction
Folio can automatically extract full **EXIF & IPTC** metadata from uploaded images when **exiftool** is available on the server.

• Install on macOS: `brew install exiftool`  
• Install on Ubuntu: `sudo apt install exiftool`

Once installed, metadata of every new image is stored in `Folio::File::Image.file_metadata`.

For existing uploads run:
```bash
rake folio:file:metadata
```
You can inspect a single image in the console:
```ruby
Dragonfly.app.fetch(Folio::File::Image.last.file_uid).metadata
``` 

---

## Navigation

- [← Back to Overview](overview.md)
- [← Back to Atoms (CMS Blocks)](atoms.md)
- [← Back to Admin Console](admin.md)
- [Next: Forms →](forms.md)
- [Extending & Customization](extending.md)

---

*For more details, see the individual chapters linked above. This files & media overview will be updated as the documentation evolves.*