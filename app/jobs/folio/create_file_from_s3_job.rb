# frozen_string_literal: true

class Folio::CreateFileFromS3Job < ApplicationJob
  include Folio::S3Client

  queue_as :default
  sidekiq_options retry: false

  def perform(s3_path:, type:, file_id: nil)
    return unless s3_path
    return unless type
    return unless type.safe_constantize && type.safe_constantize < Folio::File

    unless test_aware_s3_exists?(s3_path)
      # probably handled it already in another job
      return
    end

    broadcast_start(s3_path: s3_path)

    if file_id
      file = type.constantize.find(file_id)
      replacing_file = true
      thumbnail_keys_to_recreate = file.thumbnail_sizes.keys
    else
      file = type.constantize.new
      replacing_file = false
      thumbnail_keys_to_recreate = []
    end

    Dir.mktmpdir("folio-file-s3") do |tmpdir|
      tmp_file_path = "#{tmpdir}/#{s3_path.split("/").pop}"

      test_aware_download_from_s3(s3_path, tmp_file_path)
      test_aware_s3_delete(s3_path)

      file.file = File.open(tmp_file_path)

      if file.save
        file.try(:admin_thumb, immediate: true)

        thumbnail_keys_to_recreate.each { |thumbnail_key| file.thumb(thumbnail_key) }

        if replacing_file
          broadcast_replace_success(file: file.reload)
        else
          broadcast_success(file: file.reload, s3_path: s3_path)
        end
      else
        if replacing_file
          broadcast_replace_error(file: file)
        else
          broadcast_error(file: file, s3_path: s3_path)
        end
      end
    end
  rescue StandardError => e
    broadcast_error(file: file, s3_path: s3_path, error: e)
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
      broadcast({ s3_path: s3_path, type: "start", started_at: Time.current.to_i * 1000 })
    end

    def broadcast_success(s3_path:, file:)
      broadcast({ s3_path: s3_path, type: "success", file: serialized_file(file)[:data] })
    end

    def broadcast_error(s3_path:, file: nil, error: nil)
      if error
        errors = [error.message]
      elsif file && file.errors
        errors = file.errors.full_messages
      else
        errors = nil
      end

      broadcast({ s3_path: s3_path, type: "failure", errors: errors })
    end

    def broadcast_replace_success(file:)
      broadcast({ type: "replace-success", file: serialized_file(file)[:data] })
    end

    def broadcast_replace_error(file:, error: nil)
      if error
        errors = [error.message]
      elsif file && file.errors
        errors = file.errors.full_messages
      else
        errors = nil
      end

      broadcast({ type: "replace-failure", file: serialized_file(file)[:data], errors: errors })
    end

    def broadcast(hash)
      MessageBus.publish Folio::MESSAGE_BUS_CHANNEL,
                         {
                           type: "Folio::CreateFileFromS3Job",
                           data: hash,
                         }.to_json
    end
end
