# frozen_string_literal: true

class Folio::CreateFileFromS3Job < Folio::ApplicationJob
  include Folio::S3Client
  include Folio::Shell

  queue_as :default

  if defined?(sidekiq_options)
    sidekiq_options retry: false
  end

  def perform(s3_path:, type:, existing_id: nil, web_session_id: nil, user_id: nil)
    return unless s3_path
    unless test_aware_s3_exists?(s3_path)
      # probably handled it already in another job
      return
    end
    return unless type

    klass = type.safe_constantize
    return unless Rails.application.config.folio_direct_s3_upload_class_names.any? { |class_name| klass <= class_name.constantize }

    broadcast_start(s3_path:, file_type: type)

    file = prepare_file_model(klass, id: existing_id, web_session_id:, user_id:)
    replacing_file = file.persisted?

    Dir.mktmpdir("folio-file-s3") do |tmpdir|
      file.file = downloaded_file(s3_path, tmpdir)

      if file.save
        if replacing_file
          broadcast_replace_success(file: file.reload, file_type: type)
        else
          broadcast_success(file: file.reload, s3_path:, file_type: type)
        end
      else
        if replacing_file
          broadcast_replace_error(file:, file_type: type)
        else
          broadcast_error(file:, s3_path:, file_type: type)
        end
      end
    end
  rescue StandardError => e
    broadcast_error(file:, s3_path:, error: e, file_type: type)
    raise e
  ensure
    test_aware_s3_delete(s3_path)
  end

  private
    def broadcast_start(s3_path:, file_type:)
      broadcast({ s3_path:, type: "start", started_at: Time.current.to_i * 1000, file_type: })
    end

    def broadcast_success(s3_path:, file:, file_type:)
      broadcast({ s3_path:, type: "success", file: serialized_file(file)[:data], file_type: })
    end

    def broadcast_error(s3_path:, file: nil, error: nil, file_type:)
      if error
        errors = [error.message]
      elsif file && file.errors
        errors = file.errors.full_messages
      else
        errors = nil
      end

      broadcast({ s3_path:, type: "failure", errors:, file_type: })
    end

    def broadcast_replace_success(file:, file_type:)
      broadcast({ type: "replace-success", file: serialized_file(file)[:data], file_type: })
    end

    def broadcast_replace_error(file:, error: nil, file_type:)
      if error
        errors = [error.message]
      elsif file && file.errors
        errors = file.errors.full_messages
      else
        errors = nil
      end

      broadcast({ type: "replace-failure", file: serialized_file(file)[:data], errors:, file_type: })
    end

    def broadcast(hash)
      MessageBus.publish Folio::MESSAGE_BUS_CHANNEL,
                         {
                           type: "Folio::CreateFileFromS3Job",
                           data: hash,
                         }.to_json
    end

    def ensure_proper_file_extension_for_mime_type(tmp_file_path)
      file_mime_type = shell("file", "--brief", "--mime-type", tmp_file_path)

      ext = case file_mime_type
            when "image/jpeg"
              ".jpg"
            when "image/png"
              ".png"
            when "image/gif"
              ".gif"
            when "image/bmp"
              ".bmp"
            when "image/svg", "image/svg+xml"
              ".svg"
            else
              nil
      end

      if ext && !tmp_file_path.ends_with?(ext)
        new_file_path = "#{tmp_file_path}#{ext}"
        FileUtils.cp(tmp_file_path, new_file_path)
        new_file_path
      else
        tmp_file_path
      end
    end

    def prepare_file_model(klass, id:, web_session_id:, user_id:)
      if id
        file = klass.find(id)
      else
        file = klass.new
      end

      file.web_session_id = web_session_id if file.respond_to?("web_session_id=")
      file.user = Folio::User.find(user_id) if user_id && file.respond_to?("user=")

      file
    end

    def downloaded_file(s3_path, tmpdir)
      tmp_file_path = "#{tmpdir}/#{s3_path.split("/").pop}"

      test_aware_download_from_s3(s3_path, tmp_file_path)
      test_aware_s3_delete(s3_path)

      tmp_file_path = ensure_proper_file_extension_for_mime_type(tmp_file_path)

      File.open(tmp_file_path)
    end
end
