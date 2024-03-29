# frozen_string_literal: true

class Folio::S3::CreateFileJob < Folio::S3::BaseJob
  def perform_for_valid(s3_path:, klass:, existing_id:, web_session_id:, user_id:, attributes:)
    broadcast_start(s3_path:, file_type: klass.to_s)

    @file = prepare_file_model(klass, id: existing_id, web_session_id:, user_id:, attributes:)
    replacing_file = @file.persisted?

    Dir.mktmpdir("folio-file-s3") do |tmpdir|
      @file.file = downloaded_file(s3_path, tmpdir)

      if @file.save
        if replacing_file
          broadcast_replace_success(file: @file.reload, file_type: klass.to_s)
        else
          broadcast_success(file: @file.reload, s3_path:, file_type: klass.to_s)
        end
      else
        if replacing_file
          broadcast_replace_error(file: @file, file_type: klass.to_s)
        else
          broadcast_error(file: @file, s3_path:, file_type: klass.to_s)
        end
      end
    end
  ensure
    test_aware_s3_delete(s3_path)
  end

  private
    def downloaded_file(s3_path, tmpdir)
      tmp_file_path = "#{tmpdir}/#{s3_path.split("/").pop}"

      test_aware_download_from_s3(s3_path, tmp_file_path)

      tmp_file_path = ensure_proper_file_extension_for_mime_type(tmp_file_path)

      File.open(tmp_file_path)
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
        new_file_path = "#{tmp_file_path.gsub(/\.\w+\z/, '')}#{ext}"
        FileUtils.cp(tmp_file_path, new_file_path)
        new_file_path
      else
        tmp_file_path
      end
    end

    def prepare_file_model(klass, id:, web_session_id:, user_id:, attributes: {})
      if id
        @file = klass.find(id)
      else
        @file = klass.new
      end

      @file.web_session_id = web_session_id if @file.respond_to?("web_session_id=")
      @file.user = Folio::User.find(user_id) if user_id && @file.respond_to?("user=")

      if attributes.present?
        if attributes[:site_id].present? && @file.respond_to?("site_id=")
          @file.assign_attributes(attributes)
        else
          attributes.delete(:site_id)
          @file.assign_attributes(attributes)
        end
      end

      @file
    end
end
