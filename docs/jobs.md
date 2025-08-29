# Jobs & Background Processing

Folio defines many `ActiveJob` classes under `app/jobs/folio/`. See the [jobs directory](../app/jobs/folio) for the full list. They handle tasks such as file processing and media uploads. Some notable jobs are:

| Job class | Purpose |
|-----------|---------|
| `GenerateThumbnailJob` | Creates image thumbnails asynchronously |
| `Files::SetAdditionalDataJob` | Extracts dominant colour and animation info |
| `DeleteThumbnailsJob` | Cleans up thumbnails when a file is removed |
| `CraMediaCloud::CreateMediaJob` | Uploads videos to CraMediaCloud encoding service |
| `InvalidUsersCheckJob` | Raises an error when invalid users are detected |

Jobs use Sidekiq by default (see `config.active_job.queue_adapter`). They also broadcast updates to the admin console via MessageBus when applicable.

---

[← Back to Architecture](architecture.md)
