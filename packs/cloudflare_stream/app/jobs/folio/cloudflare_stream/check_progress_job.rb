# frozen_string_literal: true

class Folio::CloudflareStream::CheckProgressJob < Folio::ApplicationJob
  discard_on ActiveJob::DeserializationError

  queue_as :default

  unique :until_and_while_executing

  def self.remote_services_data_from(response)
    {
      "uid" => response["uid"],
      "ready_to_stream" => response["readyToStream"],
      "status" => response["status"],
      "playback" => response["playback"],
      "thumbnail" => response["thumbnail"],
      "preview" => response["preview"],
      "duration" => response["duration"],
      "iframe_url" => iframe_url_from(response),
      "require_signed_urls" => response["requireSignedURLs"],
      "error_message" => error_message_from(response),
    }.compact
  end

  def self.iframe_url_from(response)
    uid = response["uid"].presence
    playback_url = response.dig("playback", "hls").presence ||
                   response.dig("playback", "dash").presence ||
                   response["preview"].presence
    return if uid.blank? || playback_url.blank?

    uri = URI.parse(playback_url)
    "#{uri.scheme}://#{uri.host}/#{uid}/iframe"
  rescue URI::InvalidURIError
    nil
  end

  def self.error_message_from(response)
    response.dig("status", "errorReasonText").presence ||
      response.dig("status", "errorReasonCode").presence
  end

  def perform(media_file, encoding_generation: nil)
    if stale_generation?(media_file, encoding_generation)
      Rails.logger.info(
        "[CloudflareStream::CheckProgressJob] Skipping stale job for video ##{media_file.id} " \
        "job_generation=#{encoding_generation} current_generation=#{media_file.encoding_generation}"
      )
      return
    end

    uid = media_file.remote_services_data["uid"]
    if uid.blank?
      Rails.logger.error("[CloudflareStream::CheckProgressJob] Missing Cloudflare Stream uid for video ##{media_file.id}")
      raise "Missing Cloudflare Stream uid"
    end

    Rails.logger.info("[CloudflareStream::CheckProgressJob] Checking video ##{media_file.id} uid=#{uid}")

    response = Folio::CloudflareStream::Api.new.video(uid)
    updates = self.class.remote_services_data_from(response)
    updates["service"] = "cloudflare_stream"
    updates["last_progress_check_at"] = Time.current.iso8601

    if updates["ready_to_stream"]
      mark_ready!(media_file, updates)
    elsif cloudflare_error?(updates)
      mark_failed!(media_file, updates)
    elsif too_many_polls?(media_file)
      mark_failed!(media_file, updates.merge("error_message" => "Cloudflare Stream processing timed out"))
    else
      keep_processing!(media_file, updates)
    end

    broadcast_file_update(media_file)
  rescue Folio::CloudflareStream::Api::Error => e
    Rails.logger.error("[CloudflareStream::CheckProgressJob] API error for video ##{media_file.id}: #{e.message}")
    if e.not_found?
      mark_failed!(media_file, {
        "error_message" => "Cloudflare Stream video not found: #{e.message}",
        "last_progress_check_at" => Time.current.iso8601,
      })
    else
      record_api_error!(media_file, e.message)
      broadcast_file_update(media_file)
      raise
    end

    broadcast_file_update(media_file)
  end

  private
    def stale_generation?(media_file, encoding_generation)
      encoding_generation.present? &&
        media_file.encoding_generation.present? &&
        media_file.encoding_generation != encoding_generation
    end

    def cloudflare_error?(updates)
      updates.dig("status", "state").to_s == "error" || updates["error_message"].present?
    end

    def too_many_polls?(media_file)
      media_file.remote_services_data["poll_attempts"].to_i >= Rails.application.config.folio_cloudflare_stream_max_poll_attempts
    end

    def mark_ready!(media_file, updates)
      Rails.logger.info("[CloudflareStream::CheckProgressJob] Video ##{media_file.id} is ready uid=#{updates['uid']}")
      media_file.update!(remote_services_data: media_file.remote_services_data.merge(updates).merge(
        "processing_state" => "ready",
      ))
      media_file.processing_done! if media_file.may_processing_done?
    end

    def mark_failed!(media_file, updates_or_message)
      updates = updates_or_message.is_a?(Hash) ? updates_or_message : { "error_message" => updates_or_message }
      Rails.logger.warn(
        "[CloudflareStream::CheckProgressJob] Marking video ##{media_file.id} failed: " \
        "#{updates['error_message'].presence || updates.dig('status', 'state').presence || 'unknown error'}"
      )
      media_file.update!(remote_services_data: media_file.remote_services_data.merge(updates).merge(
        "service" => "cloudflare_stream",
        "processing_state" => "failed",
      ))
      media_file.processing_failed! if media_file.may_processing_failed?
    end

    def record_api_error!(media_file, message)
      timestamp = Time.current.iso8601
      media_file.update!(remote_services_data: media_file.remote_services_data.merge(
        "service" => "cloudflare_stream",
        "processing_state" => "processing",
        "last_api_error" => message,
        "last_api_error_at" => timestamp,
        "last_progress_check_at" => timestamp,
      ))
    end

    def keep_processing!(media_file, updates)
      poll_attempts = media_file.remote_services_data["poll_attempts"].to_i + 1
      Rails.logger.info(
        "[CloudflareStream::CheckProgressJob] Video ##{media_file.id} still processing " \
        "state=#{updates.dig('status', 'state')} poll_attempts=#{poll_attempts}"
      )
      media_file.update!(remote_services_data: media_file.remote_services_data.merge(updates).merge(
        "processing_state" => "processing",
        "poll_attempts" => poll_attempts,
      ))

      self.class
          .set(wait: Rails.application.config.folio_cloudflare_stream_poll_interval)
          .perform_later(media_file, encoding_generation: media_file.encoding_generation)
    end
end
