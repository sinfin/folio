# CRA Error Handling Refactor — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** When CRA encoding fails, immediately show the error to the user, do one automatic retry, and show final failure if the retry also fails.

**Architecture:** CheckProgressJob detects FAILED/ERROR from CRA, transitions AASM to `processing_failed`, schedules one retry via CreateMediaJob after 2 minutes. MonitorProcessingJob acts as safety net for lost retry jobs. EncodingInfoComponent displays error states.

**Tech Stack:** Ruby on Rails, AASM, ActiveJob, Minitest, Slim, Stimulus JS

---

### Task 1: Add `retry_processing` AASM event

**Files:**
- Modify: `/Users/jirkamotejl/folio/app/models/folio/file.rb:191-193`
- Test: `/Users/jirkamotejl/folio/test/jobs/folio/cra_media_cloud/check_progress_job_test.rb`

**Step 1: Add the event to AASM block**

In `app/models/folio/file.rb`, after the existing `processing_failed` event (line 193), add:

```ruby
event :retry_processing do
  transitions from: :processing_failed, to: :processing
end
```

**Step 2: Verify no test regressions**

Run: `cd /Users/jirkamotejl/folio && bundle exec rails test test/models/folio/file_test.rb`
Expected: All pass (no behavior change yet)

**Step 3: Commit**

```bash
git add app/models/folio/file.rb
git commit -m "feat(aasm): add retry_processing event for CRA error recovery"
```

---

### Task 2: Refactor CheckProgressJob.handle_job_failure — immediate AASM fail + retry

**Files:**
- Modify: `/Users/jirkamotejl/folio/app/jobs/folio/cra_media_cloud/check_progress_job.rb:139-152`
- Test: `/Users/jirkamotejl/folio/test/jobs/folio/cra_media_cloud/check_progress_job_test.rb:172-203`

**Step 1: Write failing tests**

Replace the existing `"FAILED job sets upload_failed state and clears progress"` test and add new tests in `check_progress_job_test.rb`:

```ruby
test "FAILED job transitions to processing_failed and schedules retry on first failure" do
  video = create_test_video_in_processing_state
  video.update!(remote_services_data: video.remote_services_data.merge(
    "processing_state" => "full_media_processing",
    "reference_id" => "REF123",
    "progress_percentage" => 45.0
  ))

  api_response = {
    "id" => "JOB123", "status" => "FAILED",
    "lastModified" => Time.current.iso8601,
    "messages" => [
      { "type" => "ERROR", "message" => "filesize mismatch" }
    ]
  }

  api_mock = Minitest::Mock.new
  api_mock.expect(:get_jobs, [api_response], [], ref_id: "REF123")

  assert_enqueued_jobs 1, only: Folio::CraMediaCloud::CreateMediaJob do
    expect_method_called_on(
      object: Folio::CraMediaCloud::Api,
      method: :new,
      return_value: api_mock
    ) do
      Folio::CraMediaCloud::CheckProgressJob.perform_now(video)
    end
  end

  video.reload
  assert_equal "processing_failed", video.aasm_state
  assert_nil video.remote_services_data["progress_percentage"]
  assert_equal "filesize mismatch", video.remote_services_data["error_message"]
  assert_equal 1, video.remote_services_data["retry_count"]
  assert video.remote_services_data["retry_scheduled_at"].present?
end

test "FAILED job on second failure is final — no retry scheduled" do
  video = create_test_video_in_processing_state
  video.update!(remote_services_data: video.remote_services_data.merge(
    "processing_state" => "full_media_processing",
    "reference_id" => "REF123",
    "retry_count" => 1
  ))

  api_response = {
    "id" => "JOB123", "status" => "FAILED",
    "lastModified" => Time.current.iso8601,
    "messages" => [
      { "type" => "ERROR", "message" => "filesize mismatch again" }
    ]
  }

  api_mock = Minitest::Mock.new
  api_mock.expect(:get_jobs, [api_response], [], ref_id: "REF123")

  assert_no_enqueued_jobs only: Folio::CraMediaCloud::CreateMediaJob do
    expect_method_called_on(
      object: Folio::CraMediaCloud::Api,
      method: :new,
      return_value: api_mock
    ) do
      Folio::CraMediaCloud::CheckProgressJob.perform_now(video)
    end
  end

  video.reload
  assert_equal "processing_failed", video.aasm_state
  assert_equal 2, video.remote_services_data["retry_count"]
  assert_nil video.remote_services_data["retry_scheduled_at"]
end
```

**Step 2: Run tests to verify they fail**

Run: `cd /Users/jirkamotejl/folio && bundle exec rails test test/jobs/folio/cra_media_cloud/check_progress_job_test.rb`
Expected: 2 new tests FAIL (old test removed, new ones not yet implemented)

**Step 3: Implement handle_job_failure**

Replace `handle_job_failure` in `check_progress_job.rb` (lines 139-152):

```ruby
def handle_job_failure(response)
  error_messages = response["messages"]&.filter_map { |msg| msg["message"] if msg["type"] == "ERROR" }&.join("; ")
  retry_count = (media_file.remote_services_data["retry_count"] || 0) + 1

  media_file.remote_services_data.merge!(
    "processing_state" => "upload_failed",
    "error_message" => error_messages || "Encoding failed",
    "failed_at" => Time.current.iso8601,
    "progress_percentage" => nil,
    "current_phase" => nil,
    "retry_count" => retry_count,
  )

  media_file.processing_failed!
  broadcast_file_update(media_file)
  broadcast_encoding_progress

  if retry_count <= 1
    media_file.remote_services_data["retry_scheduled_at"] = (Time.current + 2.minutes).iso8601
    media_file.save!
    Folio::CraMediaCloud::CreateMediaJob.set(wait: 2.minutes).perform_later(media_file)
    Rails.logger.warn "[CraMediaCloud::CheckProgressJob] Video #{media_file.id} failed (attempt #{retry_count}), scheduling retry in 2 minutes: #{error_messages}"
  else
    media_file.remote_services_data.delete("retry_scheduled_at")
    media_file.save!
    Rails.logger.error "[CraMediaCloud::CheckProgressJob] Video #{media_file.id} failed permanently (attempt #{retry_count}): #{error_messages}"
  end
end
```

Note: `processing_failed!` calls `save!` internally via AASM. The subsequent `save!` is for the retry_scheduled_at field added after the transition.

**Step 4: Run tests to verify they pass**

Run: `cd /Users/jirkamotejl/folio && bundle exec rails test test/jobs/folio/cra_media_cloud/check_progress_job_test.rb`
Expected: All PASS

**Step 5: Also fix the stale test assertion**

The test `"parses encoding messages for progress milestones"` (line 128) asserts `estimated_completion_at` which no longer exists. Remove that assertion:

```ruby
# Remove this line (128):
assert video.remote_services_data["estimated_completion_at"].present?
```

**Step 6: Commit**

```bash
git add app/jobs/folio/cra_media_cloud/check_progress_job.rb test/jobs/folio/cra_media_cloud/check_progress_job_test.rb
git commit -m "feat(cra): immediate processing_failed on CRA error with one automatic retry"
```

---

### Task 3: Update CreateMediaJob to handle retry from processing_failed

**Files:**
- Modify: `/Users/jirkamotejl/folio/app/jobs/folio/cra_media_cloud/create_media_job.rb:9-11`
- Test: `/Users/jirkamotejl/folio/test/jobs/folio/cra_media_cloud/create_media_job_test.rb`

**Step 1: Write failing test**

Add to `create_media_job_test.rb`:

```ruby
test "retries from processing_failed state via retry_processing!" do
  video = create_test_video_in_processing_state
  video.update_column(:aasm_state, "processing_failed")
  video.update!(remote_services_data: video.remote_services_data.merge(
    "retry_count" => 1,
    "retry_scheduled_at" => Time.current.iso8601
  ))

  with_mocked_s3_and_encoder(video) do |encoder_mock, api_mock|
    encoder_mock.expect(:upload_file, nil, [video], profile_group: nil, reference_id: String)
    api_mock.expect(:get_jobs, [], [], ref_id: String)

    assert_enqueued_jobs 1, only: Folio::CraMediaCloud::CheckProgressJob do
      perform_job(video, encoder_mock, api_mock)
    end
  end

  video.reload
  assert_equal "processing", video.aasm_state
  assert_equal "full_media_processing", video.remote_services_data["processing_state"]
end
```

**Step 2: Run test to verify it fails**

Run: `cd /Users/jirkamotejl/folio && bundle exec rails test test/jobs/folio/cra_media_cloud/create_media_job_test.rb -n "test_retries_from_processing_failed"`
Expected: FAIL — video is processing_failed and CreateMediaJob can't proceed

**Step 3: Implement retry transition in CreateMediaJob**

In `create_media_job.rb`, add at the beginning of `perform` (after line 10):

```ruby
def perform(media_file)
  fail "only video files are supported" unless media_file.is_a?(Folio::File::Video)

  # If retrying after failure, transition back to processing
  if media_file.processing_failed? && media_file.remote_services_data&.dig("retry_count").to_i > 0
    media_file.retry_processing!
    Rails.logger.info "[CraMediaCloud::CreateMediaJob] Video #{media_file.id} retrying after failure"
  end

  # Generate reference_id based on current file content
  current_reference_id = generate_reference_id(media_file)
  # ... rest unchanged
```

**Step 4: Run tests to verify they pass**

Run: `cd /Users/jirkamotejl/folio && bundle exec rails test test/jobs/folio/cra_media_cloud/create_media_job_test.rb`
Expected: All PASS

**Step 5: Commit**

```bash
git add app/jobs/folio/cra_media_cloud/create_media_job.rb test/jobs/folio/cra_media_cloud/create_media_job_test.rb
git commit -m "feat(cra): CreateMediaJob handles retry from processing_failed state"
```

---

### Task 4: Update MonitorProcessingJob — safety net + reduced timeouts

**Files:**
- Modify: `/Users/jirkamotejl/folio/app/jobs/folio/cra_media_cloud/monitor_processing_job.rb`
- Test: `/Users/jirkamotejl/folio/test/jobs/folio/cra_media_cloud/monitor_processing_job_test.rb`

**Step 1: Write failing tests**

Add to `monitor_processing_job_test.rb`:

```ruby
test "rescues failed video awaiting retry when retry job is lost" do
  video = create(:folio_file_video)
  video.update!(
    aasm_state: :processing_failed,
    remote_services_data: {
      "service" => "cra_media_cloud",
      "retry_count" => 1,
      "retry_scheduled_at" => 10.minutes.ago.iso8601,
    }
  )

  with_unlocked_monitor_job do
    assert_enqueued_jobs 1, only: Folio::CraMediaCloud::CreateMediaJob do
      Folio::CraMediaCloud::MonitorProcessingJob.perform_now
    end
  end
end

test "does not rescue finally failed video (retry_count >= 2)" do
  video = create(:folio_file_video)
  video.update!(
    aasm_state: :processing_failed,
    remote_services_data: {
      "service" => "cra_media_cloud",
      "retry_count" => 2,
    }
  )

  with_unlocked_monitor_job do
    assert_no_enqueued_jobs only: Folio::CraMediaCloud::CreateMediaJob do
      Folio::CraMediaCloud::MonitorProcessingJob.perform_now
    end
  end
end

test "orphan detection uses 30 minute timeout" do
  video = create(:folio_file_video)
  video.update!(
    aasm_state: :processing,
    remote_services_data: {
      "service" => "cra_media_cloud",
      "processing_state" => "creating_media_job",
      "processing_step_started_at" => 35.minutes.ago.iso8601
    }
  )

  job = Folio::CraMediaCloud::MonitorProcessingJob.new
  orphans = job.send(:find_orphaned_videos)
  assert_includes orphans, video
end
```

**Step 2: Run tests to verify they fail**

Run: `cd /Users/jirkamotejl/folio && bundle exec rails test test/jobs/folio/cra_media_cloud/monitor_processing_job_test.rb`
Expected: New tests FAIL

**Step 3: Implement changes**

3a. Add `handle_failed_videos_awaiting_retry` method and call it from `perform`:

In `perform` (line 6-26), add after `handle_failed_uploads_needing_retry`:

```ruby
def perform
  return if another_monitor_job_running?

  begin
    handle_orphaned_videos
    handle_videos_needing_upload
    handle_failed_uploads_needing_retry
    handle_failed_videos_awaiting_retry    # NEW
    handle_videos_needing_progress_check
  ensure
    release_monitor_job_lock
  end
end
```

3b. Add the new handler method (after `handle_failed_uploads_needing_retry`, ~line 128):

```ruby
def handle_failed_videos_awaiting_retry
  # Safety net: find videos that were scheduled for retry but the retry job was lost
  videos = Folio::File::Video
    .where(aasm_state: :processing_failed)
    .where("remote_services_data ->> 'service' = ?", "cra_media_cloud")
    .where("(remote_services_data ->> 'retry_count')::int < 2")
    .where("(remote_services_data ->> 'retry_scheduled_at')::timestamp < ?", 5.minutes.ago)

  return if videos.empty?

  Rails.logger.info("MonitorProcessingJob: Found #{videos.count} failed videos awaiting retry (safety net)")

  scheduled_create_jobs = find_scheduled_create_media_job_ids

  videos.each do |video|
    if scheduled_create_jobs.include?(video.id)
      Rails.logger.debug("MonitorProcessingJob: Failed video ##{video.id} already has scheduled CreateMediaJob")
      next
    end

    Rails.logger.info("MonitorProcessingJob: Re-scheduling retry for failed video ##{video.id}")
    Folio::CraMediaCloud::CreateMediaJob.perform_later(video)
  end
end
```

3c. Change orphan timeout from 3 hours to 30 minutes in `find_orphaned_videos` (line 198):

```ruby
# Change:
3.hours.ago
# To:
30.minutes.ago
```

3d. Reduce `processing_too_long?` timeout from 6h to 2h (line 343-374):

```ruby
def processing_too_long?(video)
  started_at = video.remote_services_data["processing_step_started_at"]
  return false unless started_at

  elapsed_hours = (Time.current - Time.parse(started_at)) / 1.hour

  if elapsed_hours > 2
    Rails.logger.error("MonitorProcessingJob: Marking video ##{video.id} as failed after #{elapsed_hours.round(1)} hours")

    begin
      video.processing_failed!
    rescue => e
      Rails.logger.warn("MonitorProcessingJob: AASM transition failed (#{e.message}), forcing state via update_columns")
      video.update_columns(aasm_state: "processing_failed", updated_at: Time.current)
      video.reload
    end

    return true
  elsif elapsed_hours > 1
    Rails.logger.warn("MonitorProcessingJob: Video ##{video.id} has been processing for #{elapsed_hours.round(1)} hours")
  end

  false
rescue => e
  Rails.logger.error("MonitorProcessingJob: Error checking processing time for video ##{video.id}: #{e.message}")
  false
end
```

**Step 4: Update existing test for new timeout**

Update `"marks videos as failed after processing too long"` test (line 62-79) — change `7.hours.ago` to `3.hours.ago`:

```ruby
test "marks videos as failed after processing too long" do
  video = create(:folio_file_video)
  video.update!(
    aasm_state: :processing,
    remote_services_data: {
      "service" => "cra_media_cloud",
      "processing_state" => "upload_completed",
      "processing_step_started_at" => 3.hours.ago.iso8601
    }
  )

  with_unlocked_monitor_job do
    Folio::CraMediaCloud::MonitorProcessingJob.perform_now
  end

  video.reload
  assert_equal "processing_failed", video.aasm_state
end
```

**Step 5: Run all tests**

Run: `cd /Users/jirkamotejl/folio && bundle exec rails test test/jobs/folio/cra_media_cloud/monitor_processing_job_test.rb`
Expected: All PASS

**Step 6: Commit**

```bash
git add app/jobs/folio/cra_media_cloud/monitor_processing_job.rb test/jobs/folio/cra_media_cloud/monitor_processing_job_test.rb
git commit -m "feat(cra): MonitorProcessingJob safety net for lost retries, reduce timeouts"
```

---

### Task 5: Update EncodingInfoComponent for error states

**Files:**
- Modify: `/Users/jirkamotejl/folio/app/components/folio/console/files/show/encoding_info_component.rb`
- Modify: `/Users/jirkamotejl/folio/app/components/folio/console/files/show/encoding_info_component.slim`
- Modify: `/Users/jirkamotejl/folio/app/components/folio/console/files/show/encoding_info_component.js`
- Modify: `/Users/jirkamotejl/folio/config/locales/console/files.en.yml`
- Modify: `/Users/jirkamotejl/folio/config/locales/console/files.cs.yml`

**Step 1: Update Ruby component**

Replace `encoding_info_component.rb`:

```ruby
# frozen_string_literal: true

class Folio::Console::Files::Show::EncodingInfoComponent < Folio::Console::ApplicationComponent
  def initialize(file:)
    @file = file
    @rsd = file.remote_services_data || {}
  end

  def render?
    cra_file? && (processing? || failed?)
  end

  def processing?
    @file.processing?
  end

  def failed?
    @file.processing_failed?
  end

  def retrying?
    failed? && @rsd["retry_scheduled_at"].present? && @rsd["retry_count"].to_i < 2
  end

  def current_phase
    @rsd["current_phase"]
  end

  def encoding_progress
    @rsd["progress_percentage"]
  end

  def data
    {
      "controller" => "f-c-files-show-encoding-info",
      "f-c-files-show-encoding-info-file-id-value" => @file.id,
    }
  end

  private
    def cra_file?
      @file.try(:processing_service) == "cra_media_cloud" ||
        @rsd["current_phase"].present? ||
        @rsd["retry_count"].present?
    end
end
```

**Step 2: Update Slim template**

Replace `encoding_info_component.slim`:

```slim
span.f-c-files-show-encoding-info data=data
  - if failed?
    span.f-c-files-show-encoding-info__phase.f-c-files-show-encoding-info__phase--failed
      - if retrying?
        = t(".phase_failed_retrying")
      - else
        = t(".phase_failed")
  - elsif processing?
    span.f-c-files-show-encoding-info__phase
      = t(".phase_#{current_phase}", default: current_phase&.humanize)
    - if encoding_progress.present?
      span.f-c-files-show-encoding-info__progress
        = "#{encoding_progress}%"
```

**Step 3: Update JS controller**

Replace `encoding_info_component.js`:

```javascript
window.Folio.Stimulus.register('f-c-files-show-encoding-info', class extends window.Stimulus.Controller {
  static values = {
    fileId: Number
  }

  connect () {
    this.messageBusCallbackKey = `f-c-files-show-encoding-info--${this.fileIdValue}`
    window.Folio.MessageBus.callbacks[this.messageBusCallbackKey] = (message) => {
      if (message.type === 'Folio::CraMediaCloud::CheckProgressJob/encoding_progress' &&
          message.data.id === this.fileIdValue) {
        this.update(message.data)
      }
    }
  }

  disconnect () {
    if (this.messageBusCallbackKey && window.Folio.MessageBus.callbacks) {
      delete window.Folio.MessageBus.callbacks[this.messageBusCallbackKey]
    }
  }

  update (data) {
    const phaseEl = this.element.querySelector('.f-c-files-show-encoding-info__phase')
    const progressEl = this.element.querySelector('.f-c-files-show-encoding-info__progress')

    if (data.aasm_state === 'processing_failed') {
      if (phaseEl) {
        phaseEl.classList.add('f-c-files-show-encoding-info__phase--failed')
        phaseEl.textContent = data.failed_label || ''
      }
      if (progressEl) {
        progressEl.textContent = ''
      }
      return
    }

    if (phaseEl && data.current_phase_label) {
      phaseEl.classList.remove('f-c-files-show-encoding-info__phase--failed')
      phaseEl.textContent = data.current_phase_label
    }

    if (progressEl) {
      progressEl.textContent = data.progress_percentage != null ? `${data.progress_percentage}%` : ''
    }
  }
})
```

**Step 4: Update SASS — add error color**

Add to `encoding_info_component.sass`, after `&__progress` block:

```sass
  &__phase--failed
    color: $danger
```

**Step 5: Update locale files**

In `files.en.yml`, add to encoding_info_component:

```yaml
          encoding_info_component:
            phase_waiting: "Waiting in queue"
            phase_encoding: "Encoding video"
            phase_packaging: "Packaging"
            phase_failed_retrying: "Processing failed, retrying automatically"
            phase_failed: "Processing failed. Delete the video and upload again."
```

In `files.cs.yml`:

```yaml
          encoding_info_component:
            phase_waiting: "Čekání ve frontě"
            phase_encoding: "Kódování videa"
            phase_packaging: "Balení"
            phase_failed_retrying: "Zpracování selhalo, pokusíme se znovu"
            phase_failed: "Zpracování selhalo. Smažte video a nahrajte znovu."
```

**Step 6: Update broadcast payload in CheckProgressJob**

In `broadcast_encoding_progress` method, add `failed_label`:

```ruby
def broadcast_encoding_progress
  return if message_bus_user_ids.blank?

  phase = media_file.remote_services_data["current_phase"]
  retry_count = media_file.remote_services_data["retry_count"].to_i

  failed_label = if media_file.processing_failed?
    if retry_count < 2 && media_file.remote_services_data["retry_scheduled_at"].present?
      I18n.t("folio.console.files.show.encoding_info_component.phase_failed_retrying")
    else
      I18n.t("folio.console.files.show.encoding_info_component.phase_failed")
    end
  end

  MessageBus.publish Folio::MESSAGE_BUS_CHANNEL,
                     {
                       type: "Folio::CraMediaCloud::CheckProgressJob/encoding_progress",
                       data: {
                         id: media_file.id,
                         aasm_state: media_file.aasm_state,
                         aasm_state_human: serialized_file(media_file).dig(:data, :attributes, :aasm_state_human),
                         progress_percentage: media_file.remote_services_data["progress_percentage"],
                         current_phase: phase,
                         current_phase_label: phase.present? ? I18n.t("folio.console.files.show.encoding_info_component.phase_#{phase}", default: phase.humanize) : nil,
                         failed_label: failed_label,
                         cra_status: media_file.remote_services_data["cra_status"],
                       },
                     }.to_json,
                     user_ids: message_bus_user_ids
end
```

**Step 7: Run rubocop**

Run: `cd /Users/jirkamotejl/folio && bundle exec rubocop --no-server app/jobs/folio/cra_media_cloud/check_progress_job.rb app/components/folio/console/files/show/encoding_info_component.rb`
Expected: No offenses

**Step 8: Commit**

```bash
git add app/components/folio/console/files/show/ app/jobs/folio/cra_media_cloud/check_progress_job.rb config/locales/console/files.en.yml config/locales/console/files.cs.yml
git commit -m "feat(cra): show error states in encoding info component"
```

---

### Task 6: Run full test suite and push

**Step 1: Run all CRA-related tests**

Run: `cd /Users/jirkamotejl/folio && bundle exec rails test test/jobs/folio/cra_media_cloud/`
Expected: All PASS

**Step 2: Run rubocop on all changed files**

Run: `cd /Users/jirkamotejl/folio && bundle exec rubocop --no-server app/jobs/folio/cra_media_cloud/ app/components/folio/console/files/show/encoding_info_component.rb app/models/folio/file.rb`
Expected: No offenses

**Step 3: Push folio**

```bash
cd /Users/jirkamotejl/folio && git push
```

**Step 4: Update economia**

```bash
cd /Users/jirkamotejl/economia && git checkout feature/cra-encoding-improvements
bundle update folio --conservative
git add Gemfile.lock
git commit -m "chore: update folio — CRA error handling with retry"
git push origin feature/cra-encoding-improvements
git push economia-gitlab feature/cra-encoding-improvements
```
