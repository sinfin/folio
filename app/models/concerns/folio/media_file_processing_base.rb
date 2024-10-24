# frozen_string_literal: true

module Folio::MediaFileProcessingBase
  extend ActiveSupport::Concern

  DEFAULT_PREVIEW_DURATION = 30

  PROCESSING_STATES = %w[enqueued
    full_media_processing
    full_media_processed
    preview_media_processing
    preview_media_processed]

  # TODO: split to submodules with & without preview

  included do
    after_commit :update_preview_media_length, on: :update
  end

  def process_attached_file
    regenerate_thumbnails if try(:thumbnailable?)
    self.update(remote_services_data: { "processing_step_started_at" => Time.current })
    create_full_media # ensure call processing_done! after all processing is complete
  end

  def destroy_attached_file
    delete_media_job_class.perform_later(self.remote_key) if self.remote_key
    delete_media_job_class.perform_later(self.remote_preview_key) if self.remote_preview_key
  end

  def update_preview_media_length
    # delete current preview and create new one
    # both handled by `create_preview_media`
    changes_on_duration = saved_changes["preview_track_duration_in_seconds"]
    return if changes_on_duration.blank?
    return if changes_on_duration[0].nil?
    return unless full_media_processed?

    reprocess!
    create_preview_media
  end

  def remote_services_data
    super || {}
  end

  def remote_key
    remote_services_data["remote_key"]
  end

  def remote_preview_key
    remote_services_data["remote_preview_key"]
  end

  def processing_state
    remote_services_data["processing_state"]
  end

  def processing_service
    remote_services_data["service"]
  end

  def full_media_processed!
    remote_services_data["processing_state"] = "full_media_processed"
    remote_services_data["processing_step_started_at"] = Time.current
    save!
    create_preview_media
  end

  def preview_media_processed!
    remote_services_data["processing_state"] = "preview_media_processed"
    remote_services_data["processing_step_started_at"] = Time.current
    processing_done!
  end

  def full_media_processed?
    PROCESSING_STATES.index("full_media_processed") <= PROCESSING_STATES.index(processing_state).to_i
  end

  def preview_media_processed?
    PROCESSING_STATES.index("preview_media_processed") <= PROCESSING_STATES.index(processing_state).to_i
  end

  def create_full_media
    full_media_job_class.perform_later(self)
    rsd = remote_services_data || {}
    self.update(remote_services_data: rsd.merge!({ "service" => processed_by, "processing_state" => "enqueued", "processing_step_started_at" => Time.current }))
  end

  def create_preview_media
    if preview_duration.zero?
      preview_media_processed!
    else
      preview_media_job_class.perform_later(self)
      self.update(remote_services_data: self.remote_services_data.merge!({ "processing_step_started_at" => Time.current }))
    end
  end

  def check_media_processing(preview: false)
    check_media_processing_job_class.perform_later(self, preview:)
  end

  def preview_starts_at_second
    preview_interval["start_at"]
  end

  def preview_ends_at_second
    preview_interval["end_at"]
  end

  def preview_interval
    (remote_services_data || {}).dig("preview_interval") || { "start_at" => 0, "end_at" => preview_duration_in_seconds }
  end

  def duration_in_seconds
    file_track_duration_in_seconds || (remote_services_data || {}).dig("full", "duration").to_i
  end

  def preview_duration_in_seconds
    return preview_track_duration_in_seconds if preview_track_duration_in_seconds.present?

    if (remote_services_data || {}).dig("preview_interval").present?
      preview_ends_at_second - preview_starts_at_second
    else
      [file_track_duration_in_seconds, DEFAULT_PREVIEW_DURATION].min
    end
  end

  def preview_duration=(secs)
    secs = secs.to_i if secs.is_a?(String)
    secs ||= DEFAULT_PREVIEW_DURATION
    secs = [secs, file_track_duration_in_seconds].min if file_track_duration_in_seconds.to_i.positive?

    self.preview_track_duration_in_seconds = secs
    self.remote_services_data = (remote_services_data || {}).merge("preview_interval" => { "start_at" => 0, "end_at" => secs })

    @preview_duration = ActiveSupport::Duration.build(secs)
  end

  def preview_duration
    @preview_duration ||= ActiveSupport::Duration.build(preview_duration_in_seconds)
  end
end
