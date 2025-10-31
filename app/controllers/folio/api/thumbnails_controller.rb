# frozen_string_literal: true

class Folio::Api::ThumbnailsController < Folio::Api::BaseController
  def show
    # Handle missing or malformed thumbnails parameter
    thumbnail_params = params[:thumbnails]
    return render json: [] unless thumbnail_params.is_a?(Array)

    # Limit the number of entries to prevent abuse
    thumbnail_params = thumbnail_params.first(50)

    # Create cache key from the reduced thumbnail parameters
    cache_key = "thumbnails/#{Digest::MD5.hexdigest(thumbnail_params.to_json)}"

    # Use fragment cache with 3-second expiration
    thumbnails_data = if Rails.application.config.action_controller.perform_caching
      Rails.cache.fetch(cache_key, expires_in: 3.seconds) do
        process_thumbnail_params(thumbnail_params)
      end
    else
      process_thumbnail_params(thumbnail_params)
    end

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

          thumbnails_data << {
            id: file.id,
            size: file_param[:size],
            url: thumb_result.url,
            webp_url: thumb_result.try(:webp_url)
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
