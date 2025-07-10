# frozen_string_literal: true

require "net/sftp"
require "tempfile"

module Folio
  module CraMediaCloud
    class Encoder
      DEFAULT_PROFILE_GROUP = "VoD"

      def upload_file(file, priority: "regular", profile_group: nil)
        ref_id = [file.id, Time.current.to_i].join("-")
        # Get metadata without downloading the file
        s3_metadata = get_s3_metadata(file)
        md5 = extract_etag(s3_metadata).delete_prefix('"').delete_suffix('"')
        
        xml_manifest = build_ingest_manifest(file, md5:, ref_id:, profile_group:)

        folder_path = "/ingest/#{priority}"
        file_path = "#{folder_path}/#{file.file_name}"
        xml_manifest_path = "#{folder_path}/#{file.file_name.split(".").first}_manifest.xml"

        # Use temporary file approach for reliability
        Tempfile.create(['cra_upload', '.tmp']) do |temp_file|
          # Download from S3 to temporary file
          download_s3_to_temp_file(file, temp_file)
          
          # Ensure file is written and verify size
          temp_file.flush
          temp_file.close
          actual_size = ::File.size(temp_file.path)
          
          if actual_size != file.file_size
            raise "Downloaded file size mismatch: got #{actual_size}, expected #{file.file_size}"
          end
          
          # Upload temp file to SFTP
          sftp_client do |sftp|
            sftp.upload!(temp_file.path, file_path)
            sftp.upload!(StringIO.new(xml_manifest), xml_manifest_path)
          end
          # Temp file is automatically deleted when block exits
        end

        {
          ref_id:,
          file_path:,
          xml_manifest_path:,
        }
      end

      private

        def get_s3_metadata(file)
          s3_datastore = Dragonfly.app.datastore
          s3_object_key = [s3_datastore.root_path, file.file_uid].join("/")
          s3_datastore.storage.head_object(ENV["S3_BUCKET_NAME"], s3_object_key)
        end

        def extract_etag(response)
          # Handle different response types (AWS SDK, Excon, etc.)
          if response.respond_to?(:etag)
            response.etag
          elsif response.respond_to?(:headers)
            response.headers['ETag'] || response.headers['etag'] || response.headers['Etag']
          else
            raise "Cannot extract ETag from response type: #{response.class}"
          end
        end

        def download_s3_to_temp_file(file, temp_file)
          s3_datastore = Dragonfly.app.datastore
          s3_object_key = [s3_datastore.root_path, file.file_uid].join("/")
          
          # Get the S3 object with body
          s3_response = s3_datastore.storage.get_object(ENV["S3_BUCKET_NAME"], s3_object_key)
          
          # Write the body to temp file
          temp_file.binmode
          temp_file.write(s3_response.body)
        end

        def build_ingest_manifest(file, md5:, ref_id:, profile_group:)
          xml = Builder::XmlMarkup.new; nil
          xml.instruct!(:xml, version: "1.0", encoding: "utf-8")

          xml.vod_encoder_job do
            xml.input(type: "VIDEO",
                      file: file.file_name,
                      size: file.file_size.to_s,
                      md5: md5) do
              xml.audioTrack(language: "cze", channels: "auto")
            end
            xml.profileGroup(profile_group || DEFAULT_PROFILE_GROUP)
            xml.refId(ref_id)
          end

          xml.target!
        end

        def sftp_client(&block)
          Net::SFTP.start(ENV.fetch("CRA_MEDIA_CLOUD_SFTP_HOST"),
                          ENV.fetch("CRA_MEDIA_CLOUD_SFTP_USERNAME"),
                          password: ENV.fetch("CRA_MEDIA_CLOUD_SFTP_PASSWORD"),
                          number_of_password_prompts: 0, &block)
        end
    end
  end
end
