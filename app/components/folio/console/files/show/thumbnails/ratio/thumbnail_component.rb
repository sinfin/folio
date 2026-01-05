# frozen_string_literal: true

class Folio::Console::Files::Show::Thumbnails::Ratio::ThumbnailComponent < Folio::Console::ApplicationComponent
  def initialize(thumbnail:, thumbnail_size_key:, file:)
    @thumbnail = thumbnail.is_a?(Hash) ? thumbnail : {}
    @thumbnail_size_key = thumbnail_size_key
    @file = file
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
end
