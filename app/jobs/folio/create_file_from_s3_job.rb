# frozen_string_literal: true

class Folio::CreateFileFromS3Job < ApplicationJob
  include Folio::S3Client

  queue_as :default
  sidekiq_options retry: false

  def perform(s3_path:, type:)
    return unless s3_path
    return unless type
    return unless type.safe_constantize && type.safe_constantize < Folio::File

    unless test_aware_s3_exists?(s3_path)
      # probably handled it already in another job
      return
    end

    broadcast_start(s3_path: s3_path)

    file = type.constantize.new

    Dir.mktmpdir("folio-file-s3") do |tmpdir|
      tmp_file_path = "#{tmpdir}/#{s3_path.split("/").pop}"

      test_aware_download_from_s3(s3_path, tmp_file_path)
      test_aware_s3_delete(s3_path)

      file.file = tmp_file_path

      if file.save
        broadcast_success(file: file, s3_path: s3_path)
      else
        broadcast_error(file: file, s3_path: s3_path)
      end
    end
  rescue StandardError => e
    broadcast_error(file: file, s3_path: s3_path)
    raise e
  ensure
    test_aware_s3_delete(s3_path)
  end

  private
    def serialized_file(folio_file)
      Folio::Console::FileSerializer.new(folio_file)
                                    .serializable_hash
    end

    def broadcast_start(s3_path:)
      json = { data: { s3_path: s3_path, started_at: Time.current.to_i * 1000 } }.to_json

      # TODO
    end

    def broadcast_success(s3_path:, file:)
      json = { data: { s3_path: s3_path, file: serialized_file(file) } }.to_json

      # TODO
    end

    def broadcast_error(s3_path:, file:)
      errors = model.errors.full_messages.map do |msg|
        {
          status: 400,
          title: "ActiveRecord::RecordInvalid",
          detail: msg,
        }
      end

      render json: { errors: errors }, status: 400

      json = { data: { s3_path: s3_path, errors: errors } }.to_json

      # TODO
    end
end
