# frozen_string_literal: true

class Folio::S3::DeleteJob < Folio::S3::BaseJob
  queue_as :slow

  if defined?(sidekiq_options)
    sidekiq_options retry: false
  end

  def perform(s3_path:)
    return unless s3_path
    test_aware_s3_delete(s3_path:)
  end
end
