# frozen_string_literal: true

class Folio::Console::Files::Show::Thumbnails::RatioComponent < Folio::Console::ApplicationComponent
  def initialize(file:, ratio:, thumbnail_size_keys:)
    @file = file
    @ratio = ratio
    @thumbnail_size_keys = thumbnail_size_keys
  end

  private
    def button
      render(Folio::Console::Ui::ButtonComponent.new(variant: :warning,
                                                     size: :sm,
                                                     icon: :crop,
                                                     label: t(".edit")))
    end

    def image_url
      return nil if @thumbnail_size_keys.empty?

      valid_keys = @thumbnail_size_keys.reject do |key|
        url = @file.thumb(key).url
        url&.start_with?("https://doader")
      end
      return nil if valid_keys.empty?

      highest_area_key = valid_keys.max_by do |key|
        dimensions = key.gsub(/[#>^]$/, "")
        width_str, height_str = dimensions.split("x", 2)

        if width_str.nil? || width_str.empty?
          height_str.to_i
        elsif height_str.nil? || height_str.empty?
          width_str.to_i
        else
          width_str.to_i * height_str.to_i
        end
      end

      @file.thumb(highest_area_key).url
    end
end
