# frozen_string_literal: true

class Folio::CloudflareStream::DeleteMediaJob < Folio::ApplicationJob
  discard_on ActiveJob::DeserializationError

  queue_as :default

  unique :until_and_while_executing

  def perform(identifier)
    return if identifier.blank?

    Folio::CloudflareStream::Api.new.delete(identifier)
  rescue Folio::CloudflareStream::Api::Error => e
    if e.not_found?
      Rails.logger.info("[CloudflareStream::DeleteMediaJob] Stream video already deleted: #{e.message}")
    else
      Rails.logger.warn("[CloudflareStream::DeleteMediaJob] #{e.message}")
      raise
    end
  end
end
