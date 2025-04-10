# frozen_string_literal: true

class Folio::S3::BaseJob < Folio::ApplicationJob
  include Folio::S3::Client

  queue_as :default

  if defined?(sidekiq_options)
    sidekiq_options retry: false
  end

  def perform(s3_path:, type:, message_bus_client_id: nil, existing_id: nil, web_session_id: nil, user_id: nil, attributes: {})
    return unless s3_path
    return unless type

    @message_bus_client_id = message_bus_client_id

    if !self.class.multipart? && !test_aware_s3_exists?(s3_path:)
      # probably handled it already in another job
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

  private
    def broadcast_start(s3_path:, file_type:)
      broadcast({ s3_path:, type: "start", started_at: Time.current.to_i * 1000, file_type: })
    end

    def broadcast_success(s3_path:, file:, file_type:)
      broadcast({ s3_path:, type: "success", file_id: file.id, file_type: })
    end

    def broadcast_error(s3_path:, file: nil, error: nil, file_type:)
      if error
        errors = [error.message]
      elsif file && file.errors
        errors = file.errors.full_messages
      else
        errors = nil
      end

      broadcast({ s3_path:, type: "failure", errors:, file_id: file.id, file_type: })
    end

    def broadcast_replace_success(s3_path:, file:, file_type:)
      broadcast({ type: "replace-success", file_id: file.id, file_type: })
    end

    def broadcast_replace_error(s3_path:, file:, error: nil, file_type:)
      if error
        errors = [error.message]
      elsif file && file.errors
        errors = file.errors.full_messages
      else
        errors = nil
      end

      broadcast({ type: "replace-failure", file_id: file.id, errors:, file_type: })
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
