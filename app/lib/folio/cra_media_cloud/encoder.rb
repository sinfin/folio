# frozen_string_literal: true

require "net/sftp"

module Folio
  module CraMediaCloud
    class Encoder
      SFTP_HOST = "ingest.origin.cdn.cra.cz"

      def upload_file(file, priority: "regular")
        s3_object = download_s3_object(file)

        ref_id = [file.id, Time.current.to_i].join("-")
        md5 = s3_object.headers["Etag"].delete_prefix('"').delete_suffix('"')
        xml_manifest = build_ingest_manifest(file, md5:, ref_id:)

        folder_path = "/ingest/#{priority}"
        file_path = "#{folder_path}/#{file.file_name}"
        xml_manifest_path = "#{folder_path}/#{file.file_name.split(".").first}_manifest.xml"

        sftp_client do |sftp|
          start = Time.current
          Rails.logger.info("Folio::CraMediaCloud::Encoder: Starting SFTP upload for file ##{file.id}")

          sftp.upload!(StringIO.new(s3_object.body), file_path)
          Rails.logger.info("Folio::CraMediaCloud::Encoder: Uploaded file to #{file_path}")

          sftp.upload!(StringIO.new(xml_manifest), xml_manifest_path)
          Rails.logger.info("Folio::CraMediaCloud::Encoder: Uploaded XML manifest to #{xml_manifest_path}")

          Rails.logger.info("Folio::CraMediaCloud::Encoder: Finished SFTP upload in #{(Time.current - start).round(2)} seconds")
        end

        {
          ref_id:,
          file_path:,
          xml_manifest_path:,
        }
      end

      private
        def download_s3_object(file)
          s3_datastore = Dragonfly.app.datastore
          s3_object_key = [s3_datastore.root_path, file.file_uid].join("/")
          s3_datastore.storage.get_object(ENV["S3_BUCKET_NAME"], s3_object_key)
        end

        def build_ingest_manifest(file, md5:, ref_id:)
          xml = Builder::XmlMarkup.new; nil
          xml.instruct!(:xml, version: "1.0", encoding: "utf-8")

          xml.vod_encoder_job do
            xml.input(type: "VIDEO",
                      file: file.file_name,
                      size: file.file_size,
                      md5:) do
              xml.audioTrack(language: "cze", channels: "auto")
            end
            xml.profileGroup("VoD")
            xml.refId(ref_id)
          end

          xml.target!
        end

        def sftp_client(&block)
          Net::SFTP.start(SFTP_HOST,
                          ENV["CRA_MEDIA_CLOUD_SFTP_USERNAME"],
                          password: ENV["CRA_MEDIA_CLOUD_SFTP_PASSWORD"],
                          number_of_password_prompts: 0, &block)
        end
    end
  end
end
