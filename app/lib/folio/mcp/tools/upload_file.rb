# frozen_string_literal: true

require "open-uri"

module Folio
  module Mcp
    module Tools
      class UploadFile < Base
        SUPPORTED_MIME_TYPES = {
          "image/jpeg" => { extension: ".jpg", class: -> { Folio::File::Image } },
          "image/png" => { extension: ".png", class: -> { Folio::File::Image } },
          "image/webp" => { extension: ".webp", class: -> { Folio::File::Image } },
          "image/gif" => { extension: ".gif", class: -> { Folio::File::Image } },
          "application/pdf" => { extension: ".pdf", class: -> { Folio::File::Document } },
        }.freeze

        class << self
          def call(url:, server_context:, alt: nil, title: nil, tags: [])
            config = Folio::Mcp.configuration.resources[:files]
            return error_response("File uploads not configured") unless config&.dig(:uploadable)

            user = server_context[:user]
            site = server_context[:site]

            ability = Folio::Ability.new(user, site)
            unless ability.can?(:create, Folio::File::Image.new(site: site))
              return error_response("Not authorized to upload files")
            end

            # Download and validate file
            file_data = download_and_validate_file(url)
            return error_response(file_data[:error]) if file_data[:error]

            mime_type = file_data[:mime_type]
            type_config = SUPPORTED_MIME_TYPES[mime_type]
            return error_response("Unsupported file type: #{mime_type}") unless type_config

            file_class = type_config[:class].call
            extension = type_config[:extension]

            # Create file record
            file = file_class.new(site: site, alt: alt)
            file.author = title if title.present?
            file.file = file_data[:tempfile]
            file.file_name = "upload_#{SecureRandom.hex(4)}#{extension}"
            file.tag_list = tags if tags.present? && file.respond_to?(:tag_list=)

            file.save!

            audit_log(server_context, {
              action: "upload_file",
              file_id: file.id,
              file_type: file.type,
              source_url: url
            })

            success_response({
              id: file.id,
              type: file.type,
              url: file.file.url,
              thumbnail_url: file.try(:thumb, "400x300")&.url,
              filename: file.file_name,
              width: file.try(:file_width),
              height: file.try(:file_height)
            })
          rescue OpenURI::HTTPError => e
            error_response("Failed to download file: #{e.message}")
          rescue ActiveRecord::RecordInvalid => e
            error_response("Validation failed: #{e.record.errors.full_messages.join(', ')}")
          rescue StandardError => e
            error_response("Error: #{e.message}")
          end

          private
            def download_and_validate_file(url)
              uri = URI.parse(url)
              unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
                return { error: "Invalid URL scheme - must be HTTP or HTTPS" }
              end

              options = {
                "User-Agent" => "Folio MCP/#{Folio::VERSION}",
                read_timeout: 30,
                open_timeout: 10
              }

              tempfile = Tempfile.new(["mcp_upload", ".bin"])
              tempfile.binmode

              URI.open(url, options) do |remote_file|
                tempfile.write(remote_file.read)
              end

              tempfile.rewind

              # Detect REAL mime type from file content (not HTTP header)
              mime_type = detect_mime_type(tempfile)
              return { error: "Could not detect file type from content" } unless mime_type

              type_config = SUPPORTED_MIME_TYPES[mime_type]
              return { error: "Unsupported file type: #{mime_type}" } unless type_config

              # For images, validate they can actually be processed
              if type_config[:class].call == Folio::File::Image
                validation_error = validate_image_processable(tempfile, mime_type)
                return { error: validation_error } if validation_error
              end

              # Set proper extension based on detected type
              extension = type_config[:extension]
              filename = "upload#{extension}"
              tempfile.define_singleton_method(:original_filename) { filename }

              { tempfile: tempfile, mime_type: mime_type }
            rescue OpenURI::HTTPError => e
              { error: "Failed to download: #{e.message}" }
            rescue StandardError => e
              Rails.logger.error("[MCP Upload] Download failed: #{e.class} - #{e.message}")
              { error: "Failed to download file from URL" }
            end

            def detect_mime_type(tempfile)
              tempfile.rewind

              # Use Marcel for mime type detection (bundled with Rails)
              if defined?(Marcel)
                Marcel::MimeType.for(tempfile)
              else
                # Fallback: detect from magic bytes
                detect_mime_from_magic_bytes(tempfile)
              end
            ensure
              tempfile.rewind
            end

            def detect_mime_from_magic_bytes(tempfile)
              tempfile.rewind
              header = tempfile.read(16)&.b # Read as binary
              tempfile.rewind
              return nil unless header

              if header.start_with?("\xFF\xD8\xFF".b)
                "image/jpeg"
              elsif header.start_with?("\x89PNG\r\n\x1A\n".b)
                "image/png"
              elsif header[0..3] == "RIFF" && header[8..11] == "WEBP"
                "image/webp"
              elsif header.start_with?("GIF87a") || header.start_with?("GIF89a")
                "image/gif"
              elsif header.start_with?("%PDF")
                "application/pdf"
              end
            end

            def validate_image_processable(tempfile, mime_type)
              tempfile.rewind

              # Get proper extension for the mime type
              extension = SUPPORTED_MIME_TYPES[mime_type]&.dig(:extension) || ".jpg"

              # Create a copy with proper extension for Dragonfly/libvips to process
              validation_file = Tempfile.new(["validation", extension])
              validation_file.binmode
              validation_file.write(tempfile.read)
              validation_file.rewind
              tempfile.rewind

              begin
                analyzer = Dragonfly.app.fetch_file(validation_file.path)
                width = analyzer.width
                height = analyzer.height

                if width.nil? || height.nil? || width <= 0 || height <= 0
                  return "Invalid image: could not read dimensions"
                end

                nil # No error
              rescue StandardError => e
                "Invalid image file: #{e.message}"
              ensure
                validation_file.close
                validation_file.unlink
                tempfile.rewind
              end
            end
        end
      end
    end
  end
end
