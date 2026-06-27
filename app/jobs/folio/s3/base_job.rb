# frozen_string_literal: true

require "digest"

class Folio::S3::BaseJob < Folio::ApplicationJob
  include Folio::S3::Client

  PROCESSED_UPLOAD_CACHE_EXPIRES_IN = 1.hour
  PROCESSED_UPLOAD_CACHE_PREFIX = "folio/s3/processed_upload"

  queue_as :default

  retry_on StandardError, wait: :exponentially_longer, attempts: 1

  unique :until_and_while_executing

  def self.processed_upload_cache_key(s3_path)
    "#{PROCESSED_UPLOAD_CACHE_PREFIX}/#{Digest::SHA256.hexdigest(s3_path)}"
  end

  def self.processed_upload_data(s3_path:, type:)
    data = Rails.cache.read(processed_upload_cache_key(s3_path))
    return unless data
    return unless data["file_type"] == type

    data
  end

  def self.processed_upload?(s3_path:, type:)
    processed_upload_data(s3_path:, type:).present?
  end

  def perform(s3_path:, type:, message_bus_client_id: nil, existing_id: nil, web_session_id: nil, user_id: nil, attributes: {})
    return unless s3_path
    return unless type

    @message_bus_client_id = message_bus_client_id

    if !self.class.multipart? && !test_aware_s3_exists?(s3_path:)
      return if broadcast_processed_upload_success(s3_path:, type:)

      log_missing_s3_upload(s3_path:, type:, existing_id:, web_session_id:, user_id:, message_bus_client_id:)
      broadcast_missing_s3_upload_error(s3_path:, existing_id:, type:)
      return
    end

    klass = type.safe_constantize
    return unless Rails.application.config.folio_direct_s3_upload_class_names.any? { |class_name| klass <= class_name.constantize }

    perform_for_valid(s3_path:, klass:, existing_id:, web_session_id:, user_id:, attributes:)
  rescue StandardError => e
    broadcast_error(file: @file, s3_path:, error: e, file_type: type)
    raise e
  end

  def self.multipart?
    false
  end

  def lock_key_arguments
    options = arguments.first
    return arguments unless options.respond_to?(:[])

    s3_path = options[:s3_path] || options["s3_path"]
    type = options[:type] || options["type"]

    return arguments unless s3_path && type

    [s3_path, type]
  end

  private
    def broadcast_start(s3_path:, file_type:)
      broadcast({ s3_path:, type: "start", started_at: Time.current.to_i * 1000, file_type: })
    end

    def broadcast_success(s3_path:, file:, file_type:)
      broadcast({ s3_path:, type: "success", file_id: file.id, file: serialize_file_for_broadcast(file), file_type: })
    end

    def serialize_file_for_broadcast(file)
      if file.is_a?(Folio::PrivateAttachment)
        Folio::Console::PrivateAttachmentSerializer.new(file).serializable_hash[:data]
      else
        Folio::Console::FileSerializer.new(file).serializable_hash[:data]
      end
    end

    def broadcast_error(s3_path:, file: nil, error: nil, file_type:)
      if error
        errors = [error.message]
      elsif file && file.errors
        errors = file.errors.full_messages
      else
        errors = nil
      end

      broadcast({ s3_path:, type: "failure", errors:, file_id: file&.id, file_type: })
    end

    def broadcast_replace_success(s3_path:, file:, file_type:)
      broadcast({ s3_path:, type: "replace-success", file_id: file.id, file_type: })
    end

    def broadcast_replace_error(s3_path:, file:, error: nil, file_type:)
      if error
        errors = [error.message]
      elsif file && file.errors
        errors = file.errors.full_messages
      else
        errors = nil
      end

      broadcast({ s3_path:, type: "replace-failure", file_id: file&.id, errors:, file_type: })
    end

    def register_processed_upload(s3_path:, file:, file_type:, replacing_file:)
      Rails.cache.write(processed_upload_cache_key(s3_path),
                        {
                          "file_id" => file.id,
                          "file_type" => file_type,
                          "replacing_file" => replacing_file,
                        },
                        expires_in: PROCESSED_UPLOAD_CACHE_EXPIRES_IN)
    end

    def processed_upload_cache_key(s3_path)
      self.class.processed_upload_cache_key(s3_path)
    end

    def broadcast_processed_upload_success(s3_path:, type:)
      data = self.class.processed_upload_data(s3_path:, type:)
      return false unless data

      file = type.safe_constantize&.find_by(id: data["file_id"])
      return false unless file

      if data["replacing_file"]
        broadcast_replace_success(file:, s3_path:, file_type: type)
      else
        broadcast_success(file:, s3_path:, file_type: type)
      end

      true
    end

    def log_missing_s3_upload(s3_path:, type:, existing_id:, web_session_id:, user_id:, message_bus_client_id:)
      details = {
        s3_path:,
        type:,
        existing_id:,
        web_session_id:,
        user_id:,
        message_bus_client_id:,
      }.compact

      Rails.logger.warn("[Folio::S3::CreateFileJob] File not found on S3 #{details.to_json}")
    end

    def broadcast_missing_s3_upload_error(s3_path:, existing_id:, type:)
      error = StandardError.new("File not found on S3")

      if existing_id.present?
        broadcast_replace_error(s3_path:, file: nil, error:, file_type: type)
      else
        broadcast_error(file: nil, s3_path:, error:, file_type: type)
      end
    end

    def broadcast(hash)
      return unless @message_bus_client_id

      MessageBus.publish Folio::MESSAGE_BUS_CHANNEL,
                         {
                           type: "Folio::S3::CreateFileJob",
                           data: hash,
                         }.to_json,
                         client_ids: [@message_bus_client_id]
    end
end
