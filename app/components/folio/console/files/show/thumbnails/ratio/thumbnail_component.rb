# frozen_string_literal: true

class Folio::Console::Files::Show::Thumbnails::Ratio::ThumbnailComponent < Folio::Console::ApplicationComponent
  def initialize(thumbnail:, thumbnail_size_key:)
    @thumbnail = thumbnail.is_a?(Hash) ? thumbnail : {}
    @thumbnail_size_key = thumbnail_size_key
  end

  private
    def variants
      jpg = if @thumbnail[:url].present?
        extension = begin
          File.extname(@thumbnail[:url]).delete_prefix(".").downcase
        rescue StandardError
          "jpg"
        end

        [extension.presence || "jpg", Folio::S3.cdn_url_rewrite(@thumbnail[:url])]
      else
        ["jpg", nil]
      end

      webp = if @thumbnail[:webp_url].present?
        extension = begin
          File.extname(@thumbnail[:webp_url]).delete_prefix(".").downcase
        rescue StandardError
          "webp"
        end

        [extension || "webp", Folio::S3.cdn_url_rewrite(@thumbnail[:webp_url])]
      elsif jpg[1].present? && jpg[1].start_with?("https://doader")
        ["webp", "#{jpg[1]}&webp=1"]
      else
        ["webp", nil]
      end

      [jpg, webp]
    end
end
