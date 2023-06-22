# frozen_string_literal: true

Dragonfly::S3DataStore.class_eval do
  include Folio::S3::Client

  alias_method :write_original, :write

  def write(content, opts = {})
    if content.meta && content.meta["folio_s3_path"].present?
      # copied from original except for the insides of rescuing_socket_errors block
      ensure_configured
      ensure_bucket_initialized

      headers = { "Content-Type" => content.mime_type }
      headers.merge!(opts[:headers]) if opts[:headers]
      uid = opts[:path] || generate_uid(content.name || "file")

      rescuing_socket_errors do
        # this is different
        target_path = full_path(uid)

        if content.meta["folio_s3_from_chunks"].present?
          s3_multipart_upload(s3_path: content.meta["folio_s3_path"], target_path:)
        else
          storage.copy_object(bucket_name,
                              content.meta["folio_s3_path"],
                              bucket_name,
                              target_path,
                              "x-amz-metadata-directive" => "REPLACE")
        end

        file = storage.directories.new(key: bucket_name).files.get(target_path)

        cleaned_up_headers = full_storage_headers(headers,
                                                  content.meta.without("folio_s3_path",
                                                                       "folio_s3_from_chunks"))

        file.acl = cleaned_up_headers["x-amz-acl"] || "public-read"
        file.metadata = cleaned_up_headers
        file.save
      end

      uid
    else
      write_original
    end
  end
end
