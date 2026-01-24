# frozen_string_literal: true

require "open-uri"

module Folio
  module Mcp
    module Tools
      class UploadFile < Base
        SUPPORTED_IMAGE_TYPES = %w[image/jpeg image/png image/webp image/gif].freeze
        SUPPORTED_DOCUMENT_TYPES = %w[application/pdf].freeze

        class << self
          def call(url:, server_context:, alt: nil, title: nil, tags: [])
            config = Folio::Mcp.configuration.resources[:files]
            return error_response("File uploads not configured") unless config&.dig(:uploadable)

            # Authorization check for file creation
            user = server_context[:user]
            site = server_context[:site]

            ability = Folio::Ability.new(user, site)
            unless ability.can?(:create, Folio::File::Image.new(site: site))
              return error_response("Not authorized to upload files")
            end

            # Download file
            file_data = download_file(url)
            return error_response("Failed to download file from URL") unless file_data

            # Determine file type
            content_type = file_data[:content_type]
            file_class = determine_file_class(content_type)
            return error_response("Unsupported file type: #{content_type}") unless file_class

            # Create file
            file = file_class.new(
              site: site,
              alt: alt,
              title: title
            )

            # Attach the downloaded file
            file.file = file_data[:tempfile]

            # Set tags if provided
            file.tag_list = tags if tags.present? && file.respond_to?(:tag_list=)

            file.save!

            # Audit
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
            def download_file(url)
              uri = URI.parse(url)
              return nil unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)

              tempfile = Tempfile.new(["mcp_upload", File.extname(uri.path)])
              tempfile.binmode

              options = {
                "User-Agent" => "Folio MCP/#{Folio::VERSION}",
                read_timeout: 30,
                open_timeout: 10
              }

              URI.open(url, options) do |remote_file|
                tempfile.write(remote_file.read)
                content_type = remote_file.content_type

                tempfile.rewind
                {
                  tempfile: tempfile,
                  content_type: content_type
                }
              end
            rescue StandardError
              nil
            end

            def determine_file_class(content_type)
              if SUPPORTED_IMAGE_TYPES.include?(content_type)
                Folio::File::Image
              elsif SUPPORTED_DOCUMENT_TYPES.include?(content_type)
                Folio::File::Document
              end
            end
        end
      end
    end
  end
end
