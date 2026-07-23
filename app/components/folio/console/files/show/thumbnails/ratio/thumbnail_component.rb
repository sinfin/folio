# frozen_string_literal: true

class Folio::Console::Files::Show::Thumbnails::Ratio::ThumbnailComponent < Folio::Console::ApplicationComponent
  def initialize(thumbnail:, thumbnail_size_key:, file:, variant: :default)
    @thumbnail = thumbnail.is_a?(Hash) ? thumbnail : {}
    @thumbnail_size_key = thumbnail_size_key
    @file = file
    @variant = variant
  end

  private
    def variants
      jpg = if @thumbnail[:url].present?
        extension = begin
          File.extname(@thumbnail[:url]).delete_prefix(".").downcase
        rescue StandardError
          "jpg"
        end

        url = if @thumbnail[:url].include?("doader.com")
          @file.temporary_url(@thumbnail_size_key)
        else
          Folio::S3.cdn_url_rewrite(@thumbnail[:url])
        end

        [extension.presence || "jpg", url]
      else
        ["jpg", nil]
      end

      webp = if @thumbnail[:webp_url].present? && !@thumbnail[:webp_url].include?("doader.com")
        extension = begin
          File.extname(@thumbnail[:webp_url]).delete_prefix(".").downcase
        rescue StandardError
          "webp"
        end

        [extension || "webp", Folio::S3.cdn_url_rewrite(@thumbnail[:webp_url])]
      end

      if webp
        [jpg, webp]
      else
        [jpg]
      end
    end

    def variant_class
      "f-c-files-show-thumbnails-ratio-thumbnail--detail" if @variant == :detail
    end

    def image_wrap_style
      return unless @variant == :detail

      width, height = thumbnail_dimensions
      return unless width && height

      scale = [100.0 / width, 100.0 / height].min
      scale = [scale, 1].min if regular?
      display_width = image_dimension(width * scale)
      display_height = image_dimension(height * scale)

      "width: #{display_width}px; height: #{display_height}px;"
    end

    def image_dimension(value)
      rounded_value = value.round(2)
      rounded_value.to_i == rounded_value ? rounded_value.to_i : rounded_value
    end

    def thumbnail_dimensions
      thumbnail_dimensions_from_metadata ||
        (thumbnail_dimensions_from_file if regular?) ||
        thumbnail_dimensions_from_size_key
    end

    def regular?
      !@thumbnail_size_key.end_with?("#")
    end

    def thumbnail_dimensions_from_metadata
      dimensions_from(@thumbnail[:width] || @thumbnail["width"],
                      @thumbnail[:height] || @thumbnail["height"])
    end

    def thumbnail_dimensions_from_file
      dimensions_from(@file.file_width, @file.file_height)
    end

    def thumbnail_dimensions_from_size_key
      dimensions_from(*@thumbnail_size_key.delete_suffix("#").split("x", 2))
    end

    def dimensions_from(width, height)
      width = width.to_i
      height = height.to_i
      [width, height] if width.positive? && height.positive?
    end

    def dimensions_label
      width, height = @thumbnail_size_key.delete_suffix("#").split("x", 2)
      return @thumbnail_size_key unless width.match?(/\A\d+\z/) && height.match?(/\A\d+\z/)

      "#{width}×#{height}px"
    end
end
