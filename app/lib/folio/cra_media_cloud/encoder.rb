# frozen_string_literal: true

require "net/sftp"

module Folio
  module CraMediaCloud
    class Encoder
      DEFAULT_PROFILE_GROUP = "VoD"

      # SFTP connection configuration
      SFTP_CONNECTION_TIMEOUT = 30.seconds
      SFTP_OPERATION_TIMEOUT = 60.seconds
      SFTP_MAX_RETRIES = 3
      SFTP_RETRY_DELAY = 5.seconds

      # SFTP upload configuration
      CHUNK_SIZE = 1.megabyte # Standard chunk size for file operations

      def upload_file(file, priority: "regular", profile_group: nil, reference_id: nil, media_file: nil)
        ref_id = reference_id || [file.id, Time.current.to_i].join("-")
        Rails.logger.info("[CraMediaCloud::Encoder] Starting upload for file ID: #{file.id}, ref_id: #{ref_id}")

        # Get metadata without downloading the file
        s3_metadata = get_s3_metadata(file)
        md5 = extract_etag(s3_metadata).delete_prefix('"').delete_suffix('"')

        xml_manifest = build_ingest_manifest(file, md5:, ref_id:, profile_group:)

        folder_path = "/ingest/#{priority}"
        file_path = "#{folder_path}/#{file.file_name}"
        xml_manifest_path = "#{folder_path}/#{file.file_name.split(".").first}_manifest.xml"

        # Use plain temp file path to avoid Ruby memory buffering
        temp_file_path = ::File.join(Dir.tmpdir, "cra_upload_#{ref_id}_#{Process.pid}_#{Time.current.to_i}.tmp")

        begin
          # Download using system tools (no Ruby file handles involved)
          download_to_file_path(file, temp_file_path)

          # Verify file size
          actual_size = ::File.size(temp_file_path)
          if actual_size != file.file_size
            Rails.logger.error("[CraMediaCloud::Encoder] Downloaded file size mismatch: got #{actual_size}, expected #{file.file_size}")
            raise "Downloaded file size mismatch: got #{actual_size}, expected #{file.file_size}"
          end

          # Upload to SFTP with robust session management
          with_robust_sftp_session do |sftp|
            # Use standard upload for better performance
            upload_with_retry(sftp, temp_file_path, file_path)
            Rails.logger.info("[CraMediaCloud::Encoder] File uploaded to SFTP: #{file_path}")

            # Upload manifest
            upload_with_retry(sftp, StringIO.new(xml_manifest), xml_manifest_path)
            Rails.logger.info("[CraMediaCloud::Encoder] Manifest uploaded to SFTP: #{xml_manifest_path}")
          end

        rescue => e
          Rails.logger.error("[CraMediaCloud::Encoder] Error during upload process: #{e.class}: #{e.message}")
          raise
        ensure
          # Clean up temp file
          if ::File.exist?(temp_file_path)
            begin
              ::File.delete(temp_file_path)
            rescue => e
              Rails.logger.warn("[CraMediaCloud::Encoder] Could not delete temp file #{temp_file_path}: #{e.message}")
            end
          end
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
          Rails.logger.info("[CraMediaCloud::Encoder] Fetching S3 metadata for key: #{s3_object_key}")
          s3_datastore.storage.head_object(ENV["S3_BUCKET_NAME"], s3_object_key)
        end

        def extract_etag(response)
          # Handle different response types (AWS SDK, Excon, etc.)
          if response.respond_to?(:etag)
            response.etag
          elsif response.respond_to?(:headers)
            response.headers["ETag"] || response.headers["etag"] || response.headers["Etag"]
          else
            raise "Cannot extract ETag from response type: #{response.class}"
          end
        end

        def download_to_file_path(file, file_path)
          s3_datastore = Dragonfly.app.datastore
          s3_object_key = [s3_datastore.root_path, file.file_uid].join("/")

          download_success = false

          # Try AWS CLI first (if available)
          if system("which aws > /dev/null 2>&1")
            s3_url = "s3://#{ENV['S3_BUCKET_NAME']}/#{s3_object_key}"
            aws_command = "aws s3 cp #{s3_url} #{file_path} --no-progress"

            if system(aws_command)
              download_success = true
            end
          end

          # Fallback to curl with S3 presigned URL
          unless download_success
            begin
              s3_client = s3_datastore.storage
              presigned_url = s3_client.presigned_url(
                :get_object,
                bucket: ENV["S3_BUCKET_NAME"],
                key: s3_object_key,
                expires_in: 3600
              )

              curl_command = [
                "curl", "-L", "-s", "-S",
                "-o", file_path,
                "--max-time", "1800",
                "--connect-timeout", "30",
                presigned_url
              ]

              if system(*curl_command)
                download_success = true
              end

            rescue => e
              Rails.logger.error("[CraMediaCloud::Encoder] Error generating presigned URL: #{e.message}")
            end
          end

          # Final fallback to Ruby download
          unless download_success
            Rails.logger.warn("[CraMediaCloud::Encoder] System download failed, using Ruby fallback")

            downloaded_bytes = 0

            ::File.open(file_path, "wb") do |output_file|
              loop do
                range_start = downloaded_bytes
                range_end = [downloaded_bytes + CHUNK_SIZE - 1, file.file_size - 1].min

                break if range_start >= file.file_size

                begin
                  s3_response = s3_datastore.storage.get_object(
                    ENV["S3_BUCKET_NAME"],
                    s3_object_key,
                    range: "bytes=#{range_start}-#{range_end}"
                  )

                  chunk_data = s3_response.body
                  output_file.write(chunk_data)
                  output_file.flush

                  downloaded_bytes += chunk_data.length

                  # Clear references
                  nil
                  nil

                rescue => e
                  Rails.logger.error("[CraMediaCloud::Encoder] Error downloading chunk #{range_start}-#{range_end}: #{e.message}")
                  raise "Failed to download chunk from S3: #{e.message}"
                end
              end
            end

            download_success = true
          end

          unless download_success
            raise "All download methods failed"
          end

          actual_size = ::File.size(file_path)
          if actual_size != file.file_size
            raise "Downloaded size mismatch: got #{actual_size}, expected #{file.file_size}"
          end
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

        # Robust SFTP session management with explicit cleanup
        def with_robust_sftp_session(&block)
          session = nil
          sftp = nil

          begin
            # Create SSH session with timeout configuration
            Rails.logger.info("[CraMediaCloud::Encoder] Establishing SSH session")
            session = Net::SSH.start(
              ENV.fetch("CRA_MEDIA_CLOUD_SFTP_HOST"),
              ENV.fetch("CRA_MEDIA_CLOUD_SFTP_USERNAME"),
              password: ENV.fetch("CRA_MEDIA_CLOUD_SFTP_PASSWORD"),
              number_of_password_prompts: 0,
              timeout: SFTP_CONNECTION_TIMEOUT,
              keepalive: true,
              keepalive_interval: 30
            )

            # Create SFTP session
            Rails.logger.info("[CraMediaCloud::Encoder] Establishing SFTP session")
            sftp = Net::SFTP::Session.new(session)
            sftp.connect!

            # Check if session is open and ready
            unless sftp.open?
              raise "SFTP session failed to open properly"
            end

            Rails.logger.info("[CraMediaCloud::Encoder] SFTP session established successfully")

            # Execute the block with the SFTP session
            yield(sftp)

          rescue Net::SSH::Timeout, Net::SSH::ConnectionTimeout => e
            Rails.logger.error("[CraMediaCloud::Encoder] SSH connection timeout: #{e.message}")
            raise "SSH connection timeout: #{e.message}"
          rescue Net::SSH::AuthenticationFailed => e
            Rails.logger.error("[CraMediaCloud::Encoder] SSH authentication failed: #{e.message}")
            raise "SSH authentication failed: #{e.message}"
          rescue Net::SSH::HostKeyMismatch => e
            Rails.logger.error("[CraMediaCloud::Encoder] SSH host key mismatch: #{e.message}")
            raise "SSH host key mismatch: #{e.message}"
          rescue => e
            Rails.logger.error("[CraMediaCloud::Encoder] SFTP session error: #{e.class}: #{e.message}")
            raise "SFTP session error: #{e.message}"
          ensure
            # Proper cleanup in reverse order
            begin
              if sftp && !sftp.closed?
                Rails.logger.info("[CraMediaCloud::Encoder] Closing SFTP channel")
                sftp.close_channel
              end
            rescue => e
              Rails.logger.warn("[CraMediaCloud::Encoder] Error closing SFTP channel: #{e.message}")
            end

            begin
              if session && !session.closed?
                Rails.logger.info("[CraMediaCloud::Encoder] Closing SSH session")
                session.close
              end
            rescue => e
              Rails.logger.warn("[CraMediaCloud::Encoder] Error closing SSH session: #{e.message}")
            end
          end
        end

        # Upload with retry logic for better reliability
        def upload_with_retry(sftp, source, destination, max_retries: SFTP_MAX_RETRIES)
          retries = 0
          expected_size = source.is_a?(String) ? ::File.size(source) : nil

          begin
            sftp.upload!(source, destination)

            # Verify upload for file uploads (not StringIO)
            if expected_size
              begin
                remote_attrs = sftp.stat!(destination)
                actual_size = remote_attrs.size

                if actual_size != expected_size
                  Rails.logger.error("[CraMediaCloud::Encoder] Upload size mismatch: expected #{expected_size}, got #{actual_size}")

                  # Clean up the invalid file
                  begin
                    sftp.remove!(destination)
                  rescue => cleanup_error
                    Rails.logger.warn("[CraMediaCloud::Encoder] Could not remove invalid upload: #{cleanup_error.message}")
                  end

                  raise "Upload verification failed: size mismatch (expected #{expected_size}, got #{actual_size})"
                end

                Rails.logger.info("[CraMediaCloud::Encoder] Upload verified: #{actual_size} bytes")
              rescue Net::SFTP::StatusException => e
                Rails.logger.error("[CraMediaCloud::Encoder] Could not verify upload: #{e.message}")
                raise "Upload verification failed: #{e.message}"
              end
            end

          rescue => e
            retries += 1
            if retries <= max_retries
              Rails.logger.warn("[CraMediaCloud::Encoder] Upload failed (attempt #{retries}/#{max_retries}): #{e.message}")

              # Clean up any partial upload
              if expected_size
                begin
                  sftp.remove!(destination)
                rescue => cleanup_error
                  Rails.logger.debug("[CraMediaCloud::Encoder] Could not remove partial upload: #{cleanup_error.message}")
                end
              end

              sleep(SFTP_RETRY_DELAY * retries) # Exponential backoff
              retry
            else
              Rails.logger.error("[CraMediaCloud::Encoder] Upload failed after #{max_retries} retries: #{e.message}")
              raise
            end
          end
        end
    end
  end
end
