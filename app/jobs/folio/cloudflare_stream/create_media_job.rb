# frozen_string_literal: true

class Folio::CloudflareStream::CreateMediaJob < Folio::ApplicationJob
  discard_on ActiveJob::DeserializationError

  queue_as :default

  unique :until_and_while_executing

  def perform(media_file)
    require_signed_urls = media_file.cloudflare_stream_require_signed_urls?
    allowed_origins = media_file.cloudflare_stream_allowed_origins

    Rails.logger.info(
      "[CloudflareStream::CreateMediaJob] Copying video ##{media_file.id} " \
      "allowed_origins=#{allowed_origins.size} require_signed_urls=#{require_signed_urls}"
    )

    response = Folio::CloudflareStream::Api.new.copy(
      url: media_file.cloudflare_stream_source_url,
      allowed_origins:,
      meta: {
        name: media_file.file_name.to_s,
        folio_file_id: media_file.id.to_s,
      },
      require_signed_urls:,
    )

    updates = remote_services_data_from(response)
    updates["processing_state"] = updates["ready_to_stream"] ? "ready" : "processing"
    updates["require_signed_urls"] = require_signed_urls
    updates["last_progress_check_at"] = Time.current.iso8601
    media_file.update!(remote_services_data: media_file.remote_services_data.merge(updates))

    if updates["ready_to_stream"]
      Rails.logger.info("[CloudflareStream::CreateMediaJob] Video ##{media_file.id} copied ready uid=#{updates['uid']}")
      media_file.processing_done! if media_file.may_processing_done?
    else
      Rails.logger.info(
        "[CloudflareStream::CreateMediaJob] Video ##{media_file.id} copied uid=#{updates['uid']} " \
        "state=#{updates.dig('status', 'state')}; scheduling progress check"
      )
      Folio::CloudflareStream::CheckProgressJob
        .set(wait: Rails.application.config.folio_cloudflare_stream_poll_interval)
        .perform_later(media_file, encoding_generation: media_file.encoding_generation)
    end

    broadcast_file_update(media_file)
  rescue Folio::CloudflareStream::Api::Error => e
    Rails.logger.error("[CloudflareStream::CreateMediaJob] API error for video ##{media_file.id}: #{e.message}")
    mark_failed!(media_file, e.message)
    raise
  end

  private
    def remote_services_data_from(response)
      Folio::CloudflareStream::CheckProgressJob.remote_services_data_from(response).merge(
        "service" => "cloudflare_stream",
      )
    end

    def mark_failed!(media_file, message)
      Rails.logger.warn("[CloudflareStream::CreateMediaJob] Marking video ##{media_file.id} failed: #{message}")
      media_file.update!(remote_services_data: media_file.remote_services_data.merge(
        "service" => "cloudflare_stream",
        "processing_state" => "failed",
        "error_message" => message,
      ))
      media_file.processing_failed! if media_file.may_processing_failed?
      broadcast_file_update(media_file)
    end
end
