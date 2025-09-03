# Files & Media

This chapter describes file and media management in the Folio Rails Engine, focusing on best practices and generator-based workflows for file placements, custom file types, and media handling.

---

## Introduction

Folio provides a robust system for managing files and media assets, including images, videos, documents, and more. File placements allow you to associate files with pages, atoms (CMS blocks), or other models, supporting flexible content structures.

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
  - Custom file types can be added

---

## Best Practices for Extending File Handling

- Keep file associations clear and well-documented
- Leverage metadata for advanced features (e.g., responsive images, previews)
- Use the admin console for file management whenever possible

---

## Advanced: Manual Customization

Manual editing of file or placement models is only recommended for advanced use cases.

### Form Helpers for File Placements

**Single placement**
```slim
= simple_form_for @page do |f|
  = file_picker_for_cover(f)
```
**Multiple placement**
```slim
= simple_form_for @page do |f|
  = react_images f.object.image_placements,
                 attachmentable: 'folio_page',
                 type: :image_placements
```

### Audio / Video Media
- Supported subtitle languages configured via `config.folio_files_video_enabled_subtitle_languages` (default `[%w[cs]]`).

### Image Metadata Extraction
Folio can automatically extract full **EXIF & IPTC** metadata from uploaded images when **exiftool** is available on the server.

**Installation:**
• Install on macOS: `brew install exiftool`  
• Install on Ubuntu: `sudo apt install exiftool`

**How it works:**
- Uses `multi_exiftool` gem via Dragonfly analyser
- Metadata extracted automatically on image upload (`after_assign` callback)
- All metadata stored as JSON in `file_metadata` database column
- Available helper methods: `title`, `caption`, `keywords`, `geo_location`

**Fill missing metadata:** `rake folio:file:fill_missing_metadata`

📋 **[See full Image Metadata Extraction feature specification →](../features/image_metadata_extraction.md)**

---

## Navigation

- [← Back to Overview](overview.md)
- [← Back to Atoms (CMS Blocks)](atoms.md)
- [← Back to Admin Console](admin.md)
- [Next: Forms →](forms.md)
- [Extending & Customization](extending.md)

---

*For more details, see the individual chapters linked above. This files & media overview will be updated as the documentation evolves.*
