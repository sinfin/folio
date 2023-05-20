# frozen_string_literal: true

module Folio::MediaFileProcessingBase
  extend ActiveSupport::Concern

  PROCESSING_STATES = %w[enqueued
    full_media_processing
    full_media_processed
    preview_media_processing
    preview_media_processed]


  def process_attached_file
    regenerate_thumbnails if try(:thumbnailable?)
    create_full_media # ensure call processing_done! after all processing is complete
  end

  def destroy_attached_file
    delete_media_job_class.perform_later(self.remote_key) if self.remote_key
    delete_media_job_class.perform_later(self.remote_preview_key) if self.remote_preview_key
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
    save!
    create_preview_media
  end

  def preview_media_processed!
    remote_services_data["processing_state"] = "preview_media_processed"
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
    self.remote_services_data = rsd.merge!({ "service" => processed_by, "processing_state" => "enqueued" })
  end

  def create_preview_media
    preview_media_job_class.perform_later(self)
  end

  def preview_starts_at_second
    preview_inteval["start_at"]
  end

  def preview_ends_at_second
    preview_inteval["end_at"]
  end

  def preview_inteval
    (remote_services_data || {}).dig("preview_interval") || { "start_at" => 0, "end_at" => preview_duration_in_seconds }
  end

  def duration_in_seconds
    (remote_services_data || {}).dig("full", "duration").to_i
  end

  def preview_duration=(secs)
    @preview_duration = ActiveSupport::Duration.build(secs)
    self.remote_services_data = (remote_services_data || {}).merge("preview_interval" => { "start_at" => 0, "end_at" => @preview_duration.in_seconds })
  end

  def preview_duration
    @preview_duration ||= ActiveSupport::Duration.build(preview_duration_in_seconds)
  end

  def preview_duration_in_seconds
    if (remote_services_data || {}).dig("preview_interval").present?
      preview_ends_at_second - preview_starts_at_second
    else
      30
    end
  end
end
