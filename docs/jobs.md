# Jobs & Background Processing

Folio defines many `ActiveJob` classes under `app/jobs/folio/`. See the [jobs directory](../app/jobs/folio) for the full list. They handle tasks such as file processing and media uploads. Some notable jobs are:

| Job class | Purpose |
|-----------|---------|
| `GenerateThumbnailJob` | Creates image thumbnails asynchronously |
| `Files::SetAdditionalDataJob` | Extracts dominant colour and animation info |
| `DeleteThumbnailsJob` | Cleans up thumbnails when a file is removed |
| `CraMediaCloud::CreateMediaJob` | Uploads videos to CraMediaCloud encoding service |
| `ElevenLabs::TranscribeSubtitlesJob` | Generates video subtitles using ElevenLabs Speech-to-Text API |
| `OpenAi::TranscribeSubtitlesJob` | Generates video subtitles using OpenAI Whisper API |
| `InvalidUsersCheckJob` | Raises an error when invalid users are detected |

#### Video Subtitle Transcription Jobs

Folio provides two background jobs for automatic subtitle generation:

**`Folio::ElevenLabs::TranscribeSubtitlesJob`**

Automatically transcribes video files using ElevenLabs Speech-to-Text API with automatic language detection.

**Features:**
- Automatic language detection with probability scoring
- Supports files up to 1.5 GB
- Uses expiring S3 URLs for secure cloud storage access
- Converts SRT response to VTT format
- Handles errors gracefully (file too large, no audio detected, cloud storage read failures)

**Configuration:**
- Requires `ELEVENLABS_API_KEY` environment variable
- Job class must be enabled in `Folio::File::Video.transcribe_subtitles_job_class`
- Site must have `subtitle_auto_generation_enabled: true`

**`Folio::OpenAi::TranscribeSubtitlesJob`**

Transcribes video files using OpenAI Whisper API. **Note:** This job is implemented but not currently used in production applications.

**Features:**
- Requires explicit language specification
- Compresses audio to Opus format (12k bitrate) to optimize costs
- Direct file upload to OpenAI

**Configuration:**
- Requires `OPENAI_API_KEY` environment variable
- Job class must be enabled in `Folio::File::Video.transcribe_subtitles_job_class`
- Site must have `subtitle_auto_generation_enabled: true`

**See also:** [Files & Media → Video Subtitles](files.md#video-subtitles)

Jobs use Sidekiq by default (see `config.active_job.queue_adapter`). They also broadcast updates to the admin console via MessageBus when applicable.

---

[← Back to Architecture](architecture.md)
