# frozen_string_literal: true

module Folio::S3::Client
  LOCAL_TEST_PATH = "/tmp/folio_tmp_user_photo_uploads"
  S3_TEST_PATH = "test_files"
  DIRECT_FILE_TOKEN_EXPIRES_IN = 1.hour

  def s3_client
    @s3_client ||= Aws::S3::Client.new(
    region: ENV.fetch("S3_REGION"),
    credentials: Aws::Credentials.new(
      ENV.fetch("AWS_ACCESS_KEY_ID"),
      ENV.fetch("AWS_SECRET_ACCESS_KEY"),
      ENV.fetch("AWS_SESSION_TOKEN", nil)
    )
  )
  end

  def s3_presigner
    @s3_presigner ||= Aws::S3::Presigner.new(client: s3_client)
  end

  def s3_bucket
    @s3_bucket ||= ENV.fetch("S3_BUCKET_NAME")
  end

  def s3_ls(prefix:, max_keys: 1000)
    s3_client.list_objects(
      bucket: s3_bucket,
      prefix:,
      max_keys:,
    )
  end

  def test_aware_presign_url(s3_path:, method_name: :get_object)
    if use_local_file_system?
      direct_file_storage_url(s3_path:, method_name:)
    else
      s3_presigner.presigned_url(method_name, bucket: s3_bucket, key: test_aware_s3_path(s3_path))
    end
  end

  def test_aware_download_from_s3(s3_path:, local_path:)
    if use_local_file_system?
      FileUtils.mkdir_p(File.dirname(test_aware_s3_path(s3_path)))
      FileUtils.cp(test_aware_s3_path(s3_path), local_path)
    else
      s3_client.get_object(bucket: s3_bucket,
                           key: test_aware_s3_path(s3_path),
                           response_target: local_path,
                           response_content_type: "image/jpeg")
    end
  end

  def test_aware_s3_exists?(s3_path:)
    if use_local_file_system?
      File.exist?(test_aware_s3_path(s3_path))
    else
      begin
        s3_client.head_object(
          bucket: s3_bucket,
          key: test_aware_s3_path(s3_path)
        )
        true
      rescue Aws::S3::Errors::NotFound
        false
      end
    end
  end

  def test_aware_s3_delete(s3_path:)
    if test_aware_s3_exists?(s3_path:)
      if use_local_file_system?
        FileUtils.rm(test_aware_s3_path(s3_path))
      else
        s3_client.delete_object(
          bucket: s3_bucket,
          key: test_aware_s3_path(s3_path)
        )
      end
    end
  end

  def test_aware_s3_upload(s3_path:, file:, acl: "private")
    if use_local_file_system?
      FileUtils.mkdir_p(File.dirname(test_aware_s3_path(s3_path)))
      file.rewind if file.respond_to?(:rewind)

      File.open(test_aware_s3_path(s3_path), "wb") do |f|
        IO.copy_stream(file, f)
      end
    else
      s3_client.put_object(
        bucket: s3_bucket,
        key: test_aware_s3_path(s3_path),
        body: file,
        acl:,
      )
    end
  end

  def s3_copy_object(source_key:, dest_key:)
    s3_client.copy_object(
      bucket: s3_bucket,
      copy_source: "#{s3_bucket}/#{source_key}",
      key: dest_key
    )
  end

  def s3_head_object(key:)
    s3_client.head_object(bucket: s3_bucket, key: key)
  end

  def generate_dragonfly_uid(file_name)
    if Dragonfly.app.datastore.respond_to?(:generate_uid)
      Dragonfly.app.datastore.generate_uid(file_name)
    else
      "#{Time.now.strftime '%Y/%m/%d/%H/%M/%S'}/#{SecureRandom.uuid}/#{file_name}"
    end
  end

  def dragonfly_s3_root_path
    Dragonfly.app.datastore.root_path
  end

  def verified_direct_file_s3_path(token:, method_name:)
    payload = direct_file_message_verifier.verified(token)
    fail ActiveSupport::MessageVerifier::InvalidSignature unless payload.is_a?(Hash)
    fail ActiveSupport::MessageVerifier::InvalidSignature unless payload["method_name"] == method_name.to_s

    payload["s3_path"]
  end

  # Fetch S3 HEAD metadata via Dragonfly's Fog storage layer.
  # Returns Excon response (use extract_s3_etag to read ETag).
  def s3_dragonfly_head_object(file_uid)
    s3_object_key = [dragonfly_s3_root_path, file_uid].compact_blank.join("/")
    Dragonfly.app.datastore.storage.head_object(s3_bucket, s3_object_key)
  end

  # Extract ETag from either Fog/Excon or AWS SDK response.
  def extract_s3_etag(response)
    if response.respond_to?(:etag)
      response.etag
    elsif response.respond_to?(:headers)
      response.headers["ETag"] || response.headers["etag"] || response.headers["Etag"]
    else
      raise "Cannot extract ETag from response type: #{response.class}"
    end
  end

  private
    def use_local_file_system?
      Dragonfly.app.datastore.is_a?(Dragonfly::FileDataStore)
    end

    def test_aware_s3_path(s3_path)
      if use_local_file_system?
        direct_file_upload_path(s3_path)
      elsif Rails.env.test?
        "#{S3_TEST_PATH}/#{s3_path}"
      else
        s3_path
      end
    end

    def direct_file_storage_url(s3_path:, method_name:)
      route_name = method_name.to_sym == :put_object ? :upload_folio_api_s3_path : :download_folio_api_s3_path

      Folio::Engine.routes.url_helpers.public_send(
        route_name,
        s3_path:,
        token: direct_file_upload_token(s3_path:, method_name:)
      )
    end

    def direct_file_upload_token(s3_path:, method_name:)
      direct_file_message_verifier.generate(
        {
          s3_path:,
          method_name: method_name.to_s,
        },
        expires_in: DIRECT_FILE_TOKEN_EXPIRES_IN
      )
    end

    def direct_file_message_verifier
      Rails.application.message_verifier(:folio_direct_file_upload)
    end

    def direct_file_upload_path(s3_path)
      normalized_path = normalized_direct_file_upload_path(s3_path)
      root = Pathname.new(direct_file_upload_root_path).expand_path
      path = root.join(normalized_path).cleanpath

      unless path.to_s.start_with?("#{root}/")
        fail ArgumentError, "Invalid direct upload path"
      end

      path.to_s
    end

    def normalized_direct_file_upload_path(s3_path)
      path = Pathname.new(s3_path.to_s)
      clean_path = path.cleanpath.to_s

      if s3_path.blank? ||
         path.absolute? ||
         clean_path == "." ||
         clean_path == ".." ||
         clean_path.start_with?("../")
        fail ArgumentError, "Invalid direct upload path"
      end

      clean_path
    end

    def direct_file_upload_root_path
      Rails.application.config.folio_direct_file_upload_root_path ||
        if Rails.env.test?
          LOCAL_TEST_PATH
        else
          Rails.root.join("tmp/folio_file_uploads/#{Rails.env}")
        end
    end
end
