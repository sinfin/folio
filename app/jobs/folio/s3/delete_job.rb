# frozen_string_literal: true

class Folio::S3::DeleteJob < Folio::S3::BaseJob
  queue_as :slow

  adapter_aware_sidekiq_options(retry: false)

  def perform(s3_path:)
    return unless s3_path
    test_aware_s3_delete(s3_path:)
  end
end
