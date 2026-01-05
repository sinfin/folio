# frozen_string_literal: true

class Folio::S3::DeleteJob < Folio::S3::BaseJob
  queue_as :slow

  retry_on StandardError, wait: :exponentially_longer, attempts: 1

  unique :until_and_while_executing

  def perform(s3_path:)
    return unless s3_path
    test_aware_s3_delete(s3_path:)
  end
end
