# frozen_string_literal: true

class Folio::CloudflareStream::DeleteMediaJob < Folio::ApplicationJob
  discard_on ActiveJob::DeserializationError

  queue_as :default

  unique :until_and_while_executing

  def perform(identifier)
    return if identifier.blank?

    Folio::CloudflareStream::Api.new.delete(identifier)
  rescue Folio::CloudflareStream::Api::Error => e
    Rails.logger.warn("[CloudflareStream::DeleteMediaJob] #{e.message}")
  end
end
