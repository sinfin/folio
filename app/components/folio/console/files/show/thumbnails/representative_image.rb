# frozen_string_literal: true

module Folio::Console::Files::Show::Thumbnails::RepresentativeImage
  module_function

  def representative_thumbnail_size_key(keys)
    keys.max_by do |key|
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
  end
end
