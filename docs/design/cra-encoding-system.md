# CRA Video Encoding System — Design Document

## Overview

The CRA (CraMediaCloud) integration encodes uploaded videos into multiple quality profiles (SD/HD), HLS/DASH streaming manifests, and generates thumbnails/cover images. Videos become progressively available — SD quality is playable while HD encoding continues.

**Repos:** folio gem (core engine) + economia app (overrides, player, UI)

---

## 1. Upload & Manifest Delivery

### Presigned S3 URL (no file transfer through pod)

When a video is uploaded, the encoder generates a **presigned S3 URL** (7-day expiry) and embeds it in an XML manifest. Only the manifest (~1 KB) is uploaded via SFTP — CRA fetches the video directly from S3.

```xml
<vod_encoder_job processingPhases="2">
  <input type="VIDEO" src="https://s3...?X-Amz-..." size="123456" md5="abc123">
    <audioTrack language="cze" channels="auto"/>
  </input>
  <profileGroup>VoDHDAuto</profileGroup>
  <refId>prod-video-slug-a1b2c3d4-1710000000</refId>
</vod_encoder_job>
```

### Reference ID format

`{env}-{slug(truncated)}-{s3_etag[0..7]}-{encoding_generation}`

- Total capped at **128 chars** (CRA lookup fails with longer IDs)
- `encoding_generation` changes on each re-encode, ensuring CRA gets a fresh refId

### Files

| File (folio) | Purpose |
|---|---|
| `app/lib/folio/cra_media_cloud/encoder.rb` | Builds XML manifest, uploads via SFTP |
| `app/jobs/folio/cra_media_cloud/create_media_job.rb` | Orchestrates upload: generates ref ID, checks for existing jobs, calls Encoder |
| `app/lib/folio/s3/client.rb` | Shared S3 helpers: presigned URLs, HEAD metadata, ETag extraction |

---

## 2. Two-Phase Encoding

When `encoder_processing_phases` returns `> 1` (economia overrides to `2`), a **single manifest** is submitted with the `processingPhases="2"` XML attribute. The profile group is always `VoDHDAuto` — CRA handles phasing internally.

```xml
<vod_encoder_job processingPhases="2">
  <input type="VIDEO" src="https://s3...?X-Amz-..." size="123456" md5="abc123">
    <audioTrack language="cze" channels="auto"/>
  </input>
  <profileGroup>VoDHDAuto</profileGroup>
  <refId>prod-video-slug-a1b2c3d4-1710000000</refId>
</vod_encoder_job>
```

CRA creates multiple internal jobs (one per phase), each with a `phase` field in API responses:

| CRA phase | Output | Enables |
|---|---|---|
| 1 (SD) | sd profiles, HLS/DASH (SD), cover, thumbnails | Playback at SD quality while HD encodes |
| 2 (HD) | All profiles incl. HD, full HLS/DASH | Full quality playback |

When `CheckProgressJob` sees a phase-1 job reach DONE, `save_intermediate_phase_data` writes the SD manifest/cover paths to the top-level `remote_services_data` keys the player reads — making the video playable at SD quality. It then clears `remote_id` and polls by `reference_id` to discover the phase-2 job. Phase-2 output overwrites phase-1 paths when it completes.

### Backward compatibility

When `encoder_processing_phases` is `1` or `nil` (default), the manifest is submitted without the `processingPhases` attribute. All existing behavior preserved.

### economia override (`feature/cra-encoding-improvements` branch)

```ruby
# app/overrides/models/folio/file/video_override.rb
def encoder_profile_group
  Rails.env.production? ? "VoDHDAuto" : "VoD"
end

def encoder_processing_phases
  2
end

def encoder_phase_name(phase_number)
  { 1 => "SD", 2 => "HD" }[phase_number]
end
```

---

## 3. Progress Tracking

### CRA API polling

`CheckProgressJob` polls every 15 seconds. It parses the CRA `messages` array to determine encoding phase:

| CRA message | Internal phase |
|---|---|
| `verification: finished` | `validation` |
| `Transcoding worker - audio: finished` | `audio` |
| `Transcoding worker - video: finished` | `video` |
| `copying: started` | `packaging` |

Progress percentage is raw CRA `progress` field × 100 (per-phase, not mapped across phases).

### MessageBus real-time updates

`broadcast_encoding_progress` publishes to `Folio::MESSAGE_BUS_CHANNEL` with phase label, progress %, and failure state. The `EncodingInfoComponent` Stimulus controller updates the UI badge in real time.

### Files

| File (folio) | Purpose |
|---|---|
| `app/jobs/folio/cra_media_cloud/check_progress_job.rb` | Polls CRA API, updates `remote_services_data`, handles phase transitions |
| `app/components/folio/console/files/show/encoding_info_component.*` | UI badge (Ruby + Stimulus + Sass + Slim) |

---

## 4. State Machine

### AASM states (`aasm_state` column)

```
unprocessed → [process!] → processing → [processing_done!] → ready
                                ↓
                         [processing_failed!]
                                ↓
                        processing_failed → [retry_processing!] → processing
```

### Processing states (`remote_services_data["processing_state"]`)

```
enqueued → creating_media_job → full_media_processing → full_media_processed
                                        ↓
                                 encoding_failed (CRA FAILED/ERROR)
                                 upload_failed   (SFTP/S3 error in CreateMediaJob)
                                 source_file_missing (S3 404)
```

Multi-phase adds intermediate data (`phase_N_content_mp4_paths`, `phase_N_completed_at`) but no new processing states.

### `remote_services_data` JSON structure

```json
{
  "service": "cra_media_cloud",
  "processing_state": "full_media_processing",
  "reference_id": "prod-video-slug-a1b2c3d4-1710000000",
  "remote_id": "JOB123",
  "encoding_generation": 1710000000,
  "processing_step_started_at": "2026-03-17T10:30:00Z",

  "cra_status": "PROCESSING",
  "progress_percentage": 60,
  "current_phase": "encoding",
  "current_encoding_phase": 1,
  "processing_phases": 2,
  "phases_completed": ["validation", "audio"],
  "video_duration": 120,

  "phase_1_content_mp4_paths": { "sd0": "/path/sd0.mp4", "sd1": "/path/sd1.mp4" },
  "phase_1_completed_at": "2026-03-17T11:00:00Z",
  "phase_1_remote_id": "JOB111",

  "content_mp4_paths": { "sd0": "/path/sd0.mp4", "hd1": "/path/hd1.mp4" },
  "manifest_hls_path": "/path/master.m3u8",
  "manifest_dash_path": "/path/manifest.mpd",
  "cover_path": "/path/cover.jpg",
  "thumbnails_path": "/path/thumb.vtt",

  "error_message": null,
  "retry_count": 0,
  "retry_scheduled_at": null,
  "failed_at": null
}
```

---

## 5. Error Handling & Recovery

### Automatic retry

On CRA `FAILED`/`ERROR`, `CheckProgressJob`:
1. Sets `processing_state` to `"encoding_failed"`, `retry_count` += 1
2. Calls `processing_failed!` (single save)
3. Broadcasts failure state to UI
4. If `retry_count <= 1`: schedules `CreateMediaJob` in 2 minutes
5. If `retry_count > 1`: final failure, no retry

### Timeout

- **CheckProgressJob**: 4-hour `MAX_PROCESSING_DURATION` — marks as `processing_failed` if `processing_step_started_at` is older
- **MonitorProcessingJob**: 6-hour hard timeout (× phase multiplier), 2-hour warning threshold

### Safety nets (MonitorProcessingJob)

Runs periodically with Redis lock to prevent concurrent instances. Catches:

| Scenario | Action |
|---|---|
| Stuck in `unprocessed` with `file_uid` > 5 min | Triggers `process!` |
| Stuck in `enqueued` > 10 min | Re-enqueues `CreateMediaJob` |
| `upload_failed` / `encoding_failed` > 5 min | Re-enqueues `CreateMediaJob` |
| `processing_failed` with `retry_count < 2` and lost retry job | Re-enqueues `CreateMediaJob` |
| Processing > 6 hours | Marks as `processing_failed` |
| Orphaned (has `reference_id` but no `remote_id`, or stuck in `creating_media_job` > 30 min) | Reconciles via API |

### Missing S3 source file

If S3 returns 404 during `CreateMediaJob`, video is marked `source_file_missing` + `processing_failed` permanently (no retry).

---

## 6. Progressive Video Availability

After phase 1 completes, `save_intermediate_phase_data` writes SD manifest/cover paths to the same top-level keys the player reads (`manifest_hls_path`, `manifest_dash_path`, `cover_path`). The video is playable at SD quality while AASM state remains `processing`.

The economia `PlayerComponent` gates on manifest URL presence (not AASM `ready?`):
```ruby
@valid = @file.remote_manifest_hls_url.present? || @file.remote_manifest_dash_url.present?
```

When phase 2 completes, `process_output_hash` overwrites with HD paths. Next page load serves HD.

### Console video detail (economia)

`AdditionalHtmlComponent` shows:
- **Iframe with player** when manifest URL is present (same gate as PlayerComponent — manifest is available as soon as phase 1 completes, so this covers the SD-quality interim state)
- **"File not ready"** when no manifest is available yet

---

## 7. Thumbnail Generation

Priority order:
1. **CRA cover image** (small JPEG from CDN) — preferred, no decoding needed
2. **ffmpeg frame extraction** — only for ≤4K resolution (checked via `ffprobe`)
3. **Fallback placeholder** (`missing-video.png`) — for >4K or when both above fail

Both ffprobe (resolution check) and ffmpeg (frame extraction) receive the **presigned S3 URL** from `file_url_or_path`. ffprobe reads only container headers (no full download). ffmpeg uses `-ss` before `-i` for fast HTTP range-based seeking, avoiding a full file download to the pod.

### OOMKill prevention

Videos >4K (2160p) skip ffmpeg decoding entirely — HEVC reference frame buffers can require 800+ MB. The fallback placeholder is used until CRA provides the cover image.

### Files

| File (folio) | Purpose |
|---|---|
| `app/jobs/folio/generate_thumbnail_job.rb` | Video screenshot extraction with resolution check |
| `app/jobs/folio/file/get_video_metadata_job.rb` | Single ffprobe call for duration + dimensions via presigned URL |

---

## 8. S3 Optimizations

| Optimization | File | Effect |
|---|---|---|
| Presigned URL for CRA | `encoder.rb` | No video download to pod |
| Presigned URL for ffprobe | `file.rb` → `file_url_or_path` | Streams ~100 KB headers, not full file |
| S3 server-side copy for uploads | `app/jobs/folio/s3/create_file_job.rb` | Zero data transfer for video copy |
| Shared S3 helpers | `app/lib/folio/s3/client.rb` | `s3_dragonfly_head_object`, `extract_s3_etag` |

---

## 9. Legacy Video Support (economia)

Videos imported from old Wowza/CDN77 system have `legacy_data["skip_cra_encoding"] = true`. These:
- Skip CRA encoding entirely (`process_attached_file` → just thumbnails + `processing_done!`)
- Use direct CDN URLs for playback
- Override `remote_manifest_url_base` and `remote_content_url_base` to match import domain
- Skip CRA delete on destroy

### Files (economia, branch `feature/cra-encoding-improvements`)

| File | Purpose |
|---|---|
| `app/overrides/models/folio/file/video_override.rb` | CRA concern inclusion, profile group, 2-phase config, legacy video handling |
| `app/overrides/jobs/folio/cra_media_cloud/create_media_job_override.rb` | Sets queue to `:video` |
| `app/components/economia/cra_media_cloud/player_component.rb` | OTT player rendering with manifest-based gate, subtitles, Gemius analytics |
| `app/components/economia/cra_media_cloud/player_component.js` | Stimulus controller: player lifecycle, viewport awareness, multi-instance coordination |
| `app/components/folio/console/economia/files/additional_html_component.rb` | Console video detail: iframe player (manifest gate) + manifest URL links |
| `app/components/folio/console/economia/files/additional_html_component.slim` | Template with manifest gate — shows player iframe or "not ready" |
| `app/jobs/economia/import_video_from_url_job.rb` | Legacy video import from article URLs |
| `app/lib/economia/article_storage/video_creator.rb` | Creates video records from Article Storage API |
| `lib/tasks/cra_audit.rake` | CRA audit rake task (330 lines) |

---

## 10. Environment Variables

```
# SFTP (manifest upload)
CRA_MEDIA_CLOUD_SFTP_HOST / _USERNAME / _PASSWORD

# API (job status polling)
CRA_MEDIA_CLOUD_API_BASE_URL / _USERNAME / _PASSWORD

# CDN (output URLs)
CRA_MEDIA_CLOUD_CDN_CONTENT_URL    # MP4, cover, thumbnails
CRA_MEDIA_CLOUD_CDN_MANIFEST_URL   # HLS/DASH manifests

# S3
S3_BUCKET_NAME / S3_REGION / AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY
```

---

## 11. Known Gaps & TODO

### Not yet implemented

- [ ] **Subtitle trigger on SD completion** — ElevenLabs transcription from sd1 MP4 after phase 1. Not wired up.
- [ ] **Dynamic timeouts in MonitorProcessingJob** — currently fixed 6h. Design doc specified file-size/duration-based formula.
- [ ] **`playable` field in API JSON** — `videos_controller.rb` still returns `ready: video.ready?`. Should add `playable:` based on manifest presence.
- [ ] **SD quality badge on player** — no visual indicator that video is SD-only while HD encodes.

### Test coverage gaps (folio)

- [ ] MonitorProcessingJob handler integration tests (`handle_videos_needing_upload`, `handle_orphaned_videos`, `reconcile_video_state`)
- [ ] Encoder: `upload_file` method, SFTP session management, retry logic
- [ ] CreateFileJob: S3 server-side copy path for videos
- [ ] AASM state transition integration tests with CRA concern

### Test coverage gaps (economia)

- [ ] `AdditionalHtmlComponent` — additional state coverage (legacy video, unprocessed video)
