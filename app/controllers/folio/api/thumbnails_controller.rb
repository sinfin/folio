# frozen_string_literal: true

class Folio::Api::ThumbnailsController < Folio::Api::BaseController
  def show
    # Handle missing or malformed thumbnails parameter
    thumbnail_params = params[:thumbnails]

    # If thumbnails parameter is a string (from URL query), parse it as JSON
    if thumbnail_params.is_a?(String)
      begin
        thumbnail_params = JSON.parse(thumbnail_params)
      rescue JSON::ParserError
        return render json: []
      end
    end

    return render json: [] unless thumbnail_params.is_a?(Array)

    # Limit the number of entries to prevent abuse
    thumbnail_params = thumbnail_params.first(50)

    # Create cache key from the reduced thumbnail parameters
    cache_key = "thumbnails/#{Digest::MD5.hexdigest(thumbnail_params.to_json)}"

    # Use fragment cache with 2-second expiration
    thumbnails_data = if Rails.application.config.action_controller.perform_caching
      Rails.cache.fetch(cache_key, expires_in: 2.seconds) do
        process_thumbnail_params(thumbnail_params)
      end
    else
      process_thumbnail_params(thumbnail_params)
    end

    # Set cache headers to match fragment cache duration (2 seconds)
    # Short TTL because thumbnail status changes rapidly during generation
    response.headers["Cache-Control"] = "max-age=2, must-revalidate, stale-while-revalidate=1, stale-if-error=10"

    render json: thumbnails_data
  end

  private
    def process_thumbnail_params(thumbnail_params)
      thumbnails_data = []

      # Extract file IDs and group parameters by file ID
      params_by_file_id = {}
      thumbnail_params.each do |thumbnail_param|
        # Skip parameters without required values
        next unless thumbnail_param.respond_to?(:[])

        id_value = thumbnail_param["id"]
        size_value = thumbnail_param["size"]
        next unless id_value.present? && size_value.present?

        file_id = id_value.to_i
        params_by_file_id[file_id] ||= []
        params_by_file_id[file_id] << { id: id_value, size: size_value }
      end

      # Load all files at once to avoid N+1 queries
      file_ids = params_by_file_id.keys
      files = Folio::File.where(id: file_ids).index_by(&:id)

      # Process each file and its parameters
      params_by_file_id.each do |file_id, file_params|
        file = files[file_id]

        # Skip if file doesn't exist
        next unless file

        # Skip non-image files (only images can have thumbnails)
        next unless file.respond_to?(:thumb) && file.thumbnailable?

        # Process each size parameter for this file
        file_params.each do |file_param|
          # Generate thumbnail and get URLs
          thumb_result = file.thumb(file_param[:size])

          # Skip private thumbnails
          next if thumb_result.try(:private)

          # Get URLs and check if they're ready (don't contain doader.com placeholder)
          url = thumb_result.url
          webp_url = thumb_result.try(:webp_url)

          # Check if thumbnail is ready - both URL and WebP URL must not contain doader.com
          url_ready = url.present? && !url.include?("doader.com")
          webp_url_ready = webp_url.blank? || !webp_url.include?("doader.com")
          ready = url_ready && webp_url_ready

          thumbnails_data << {
            id: file.id,
            size: file_param[:size],
            url: ready ? url : nil,
            webp_url: ready ? webp_url : nil,
            width: thumb_result.width,
            height: thumb_result.height,
            ready: ready
          }
        rescue => e
          # Log error but continue processing other parameters
          Rails.logger.warn "Error processing thumbnail for file #{file.id}, size #{file_param[:size]}: #{e.message}"
          next
        end
      end

      thumbnails_data
    end
end
