# frozen_string_literal: true

class Folio::Console::Files::Show::Thumbnails::Ratio::ThumbnailComponent < Folio::Console::ApplicationComponent
  def initialize(thumbnail:, thumbnail_size_key:)
    @thumbnail = thumbnail.is_a?(Hash) ? thumbnail : {}
    @thumbnail_size_key = thumbnail_size_key
  end

  private
    def variants
      source = [ [:url, "jpg"], [:webp_url, "webp"] ]

      source.map do |key, default_ext|
        if @thumbnail[key].present?
          extension = begin
            File.extname(@thumbnail[key]).delete_prefix(".").downcase
          rescue StandardError
            default_ext
          end

          [extension, Folio::S3.cdn_url_rewrite(@thumbnail[key])]
        else
          [default_ext, nil]
        end
      end
    end
end
