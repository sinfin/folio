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

#### Video Subtitles

Folio supports automatic subtitle generation for video files using AI transcription services. Subtitles are stored in VTT format and can be manually edited in the admin console.

**Supported subtitle languages:**
- Configured via `config.folio_files_video_enabled_subtitle_languages` (default `[%w[cs]]`)
- Site-specific languages can be configured via `Folio::Site#subtitle_languages`

**Automatic subtitle generation:**

Folio supports two transcription providers:

1. **ElevenLabs Speech-to-Text** (recommended, used in production)
   - Automatic language detection
   - Supports files up to 1.5 GB
   - Uses cloud storage URLs for processing
   - Returns SRT format, converted to VTT

2. **OpenAI Whisper** (alternative, not currently used in production)
   - Requires explicit language specification
   - Compresses audio to optimize costs
   - Direct file upload

**Configuration:**

To enable automatic subtitle generation, configure the transcription job in your application:

```ruby
# In app/models/folio/file/video.rb or app/overrides/models/folio/file/video_override.rb
module Folio::File::Video
  class_methods do
    def transcribe_subtitles_job_class
      Folio::ElevenLabs::TranscribeSubtitlesJob  # Recommended: used in production
      # Folio::OpenAi::TranscribeSubtitlesJob    # Alternative: not currently used
    end
  end
end
```

**Environment variables:**

For ElevenLabs (recommended):
- `ELEVENLABS_API_KEY` - Your ElevenLabs API key

For OpenAI (alternative, not used in production):
- `OPENAI_API_KEY` - Your OpenAI API key

**How it works:**

1. When a video is uploaded and `site.subtitle_auto_generation_enabled` is `true`, transcription starts automatically
2. The job sends the video URL to the transcription service
3. ElevenLabs automatically detects the language (with probability score)
4. The detected language is matched against site's enabled subtitle languages
5. If probability > 50% and language is enabled, subtitles are generated in that language
6. Otherwise, fallback to default language (`Folio::VideoSubtitle.default_language`)
7. Subtitles are converted to VTT format and stored in `Folio::VideoSubtitle` model
8. Subtitles can be manually edited or regenerated in the admin console

**File size limits:**

- ElevenLabs: Maximum 1.5 GB (1536 MB)
- Files exceeding the limit will show an error message

**Subtitle states:**

- `pending` - Not yet generated
- `processing` - Transcription in progress
- `ready` - Subtitles generated and enabled
- `processing_failed` - Transcription failed (error message stored)

**Manual subtitle management:**

Subtitles can be manually uploaded, edited, or regenerated via the admin console at `/console/file/videos/:id`.

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

📋 **[See full Image Metadata Extraction feature specification →](./plans/image_metadata_extraction_plan.md)**

---

## Shared file usage for child records

Records rendered inside one published parent can share that parent's file
license. Both models must include `Folio::HasAttachments` and explicitly name
the associations:

```ruby
class Blog::Article < ApplicationRecord
  include Folio::HasAttachments
  has_many :posts, class_name: "Blog::Post", inverse_of: :article

  self.folio_file_usage_child_associations = [:posts]
end

class Blog::Post < ApplicationRecord
  include Folio::HasAttachments
  belongs_to :article, class_name: "Blog::Article", inverse_of: :posts

  self.folio_file_usage_parent_association = :article
end
```

The parent association must be a direct, non-polymorphic `belongs_to`.
Polymorphic parents raise an `ArgumentError` identifying the misconfigured
association.

For STI models, set `folio_file_usage_parent_association` on the child model's
Active Record base class, not only on a subclass. Subclasses inherit the
configuration. File placements store `base_class.name`, and the usage counter
resolves the parent association from that base class.

The parent must expose `published` and provide `site` / `site_id` for site-based
licenses. Published children and their atoms count under the parent's ID and
site; unpublished children and unpublished parents do not consume a usage.
Children without a `published` column follow their parent's publication state.
The same photo across the parent and its children consumes one usage. A new
child's picker receives the persisted parent's signed context, with the same
permission and site checks as a picker on the parent.

When enabling this configuration for existing records, recalculate the affected
files with `update_file_placements_counts!` as part of the host application's
post-deploy work so stored counts match the new grouping.

## Navigation

- [← Back to Overview](overview.md)
- [← Back to Atoms (CMS Blocks)](atoms.md)
- [← Back to Admin Console](admin.md)
- [Next: Forms →](forms.md)
- [Extending & Customization](extending.md)

---

*For more details, see the individual chapters linked above. This files & media overview will be updated as the documentation evolves.*
