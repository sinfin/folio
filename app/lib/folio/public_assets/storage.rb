# frozen_string_literal: true

class Folio::PublicAssets::Storage
  include Folio::S3::Client

  LOCAL_ROOT = File.join(Dir.tmpdir, "folio_public_assets")

  def self.root_path
    return "public_assets" if Rails.env.test?

    "#{ENV.fetch('PROJECT_NAME')}/#{ENV.fetch('DRAGONFLY_RAILS_ENV') { Rails.env }}/public_assets"
  end

  def write(upload:, token:, file_name:, mime_type:)
    key = new_key(token:, file_name:)
    if use_local_file_system?
      FileUtils.mkdir_p(File.dirname(local_path(key:)))
      FileUtils.cp(upload.path, local_path(key:))
    else
      upload.tempfile.rewind
      s3_client.put_object(bucket: s3_bucket, key:, body: upload.tempfile, content_type: mime_type)
    end
    key
  end

  def read(key:)
    if use_local_file_system?
      File.binread(local_path(key:))
    else
      s3_client.get_object(bucket: s3_bucket, key:).body.read
    end
  end

  def delete(key:)
    return if key.blank?

    if use_local_file_system?
      FileUtils.rm_f(local_path(key:))
    else
      s3_client.delete_object(bucket: s3_bucket, key:)
    end
  end

  private
    def use_local_file_system?
      Rails.env.test?
    end

    def new_key(token:, file_name:)
      "#{self.class.root_path}/#{token}/#{SecureRandom.uuid}/#{file_name}"
    end

    def local_path(key:)
      File.join(LOCAL_ROOT, key)
    end
end
