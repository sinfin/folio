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

#### Video Playback Providers

`Folio::File::Video` exposes a provider-neutral playback contract so host applications do not need to read provider-specific `remote_services_data` directly.

Public playback methods:

| Method | Purpose |
|--------|---------|
| `video_playback_provider_key` | Active provider key, e.g. `direct_file`, `cloudflare_stream`, or `cra_media_cloud` |
| `video_playback_ready?` | Whether the video is playable on the public site |
| `video_playback_sources` | HTML5 player sources (`src`, `type`, optional `label`) |
| `video_playback_embed_url` | Provider iframe/player URL when available |
| `video_playback_poster_url` | Poster/thumbnail URL |
| `video_processing_state` | Normalized state: `pending`, `processing`, `ready`, `failed` |
| `video_processing_error_message` | Safe processing error text for UI |
| `video_seo_metadata` | Provider-aware SEO metadata for JSON-LD and video sitemaps |

Default configuration:

```ruby
Rails.application.config.folio_files_video_default_processing_provider = :direct_file
Rails.application.config.folio_files_video_playback_provider_classes = {
  "direct_file" => "Folio::Video::Providers::DirectFile",
  "cloudflare_stream" => "Folio::Video::Providers::CloudflareStream",
  "cra_media_cloud" => "Folio::Video::Providers::CraMediaCloud",
}
```

The direct-file provider is intended as a simple fallback and must not expose a permanent public URL of the original uploaded file in SEO metadata or public serializers. External processing providers should receive source files through short-lived server-generated URLs and expose only their stable playback outputs.

Cloudflare Stream can be enabled by including `Folio::CloudflareStream::FileProcessing` in the host application's video override and configuring `folio_cloudflare_stream_account_id` and `folio_cloudflare_stream_api_token`.

Typical host application ENV:

```sh
CLOUDFLARE_STREAM_ACCOUNT_ID=todo-account-id
CLOUDFLARE_STREAM_CUSTOMER_SUBDOMAIN=customer-code.cloudflarestream.com
CLOUDFLARE_STREAM_API_TOKEN=find-me-in-vault
CLOUDFLARE_STREAM_ALLOWED_ORIGINS=www.example.com,example.com
CLOUDFLARE_STREAM_REQUIRE_SIGNED_URLS=false
CLOUDFLARE_STREAM_SIGNED_URL_TOKEN_EXPIRES_IN=3600
CLOUDFLARE_STREAM_MONITOR_STALE_AFTER=300
```

Only `CLOUDFLARE_STREAM_ACCOUNT_ID` and `CLOUDFLARE_STREAM_API_TOKEN` are required by the provider. `CLOUDFLARE_STREAM_CUSTOMER_SUBDOMAIN` is optional operational context for manually checking playback URLs; Cloudflare Stream API responses already include the customer subdomain in `thumbnail`, `preview`, HLS and DASH URLs.

`CLOUDFLARE_STREAM_ALLOWED_ORIGINS` restricts where new Stream videos can be embedded. Leave it blank to allow any origin. `CLOUDFLARE_STREAM_REQUIRE_SIGNED_URLS` defaults to `false`; public SEO videos should stay unsigned, while host applications can opt protected videos into signed playback by overriding the per-file hook. Signed playback tokens use `CLOUDFLARE_STREAM_SIGNED_URL_TOKEN_EXPIRES_IN` as their lifetime. `CLOUDFLARE_STREAM_MONITOR_STALE_AFTER` controls the optional monitor backstop for lost progress polling jobs.

The API token must be scoped to the target account with Stream Write permission. The provider uploads via Cloudflare Stream `/stream/copy` using the `input` field and stores only stable provider playback outputs. The source URL must be publicly routable and support both `HTTP HEAD` and `HTTP GET` range requests. It must not expose a permanent public URL of the original Folio storage file.

Cloudflare Stream provider features:

| Feature | Status | Notes |
|---------|--------|-------|
| Upload from URL | Supported | Uses `/stream/copy` with `input` set to a short-lived source URL. |
| Processing polling | Supported | Stores normalized processing state, records the last progress check time, and schedules follow-up checks until ready, failed, or timed out. |
| Processing monitor | Supported | Optional `Folio::CloudflareStream::MonitorProcessingJob` backstop re-enqueues stale progress checks from host application cron. |
| Playback metadata | Supported | Stores Stream `uid`, HLS/DASH playback URLs, thumbnail, preview, and iframe player URL. |
| Public player contract | Supported | Exposes provider data through `video_playback_*` and `video_seo_metadata`, not through direct reads of provider JSON. |
| Embed origin restrictions | Supported | Sends configured `allowedOrigins` for newly created Stream videos. |
| Signed playback URLs | Supported per file | Defaults to unsigned; host applications can override `cloudflare_stream_require_signed_urls?` for protected videos. |
| Remote deletion | Supported | Deletes the Stream video when a processed file with a Stream `uid` is destroyed. |
| Browser direct creator uploads | Not implemented | Keep using Folio storage as the canonical source. Direct creator uploads would require a separate browser-to-Stream flow. |

Provider switching is non-destructive. Existing videos keep their stored provider playback metadata until the host application explicitly reprocesses or migrates that file.

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
