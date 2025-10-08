# frozen_string_literal: true

class Folio::Console::Files::Show::ThumbnailsComponent < Folio::Console::ApplicationComponent
  def initialize(file:)
    @file = file
  end

  def self.group_thumbnail_size_keys(keys)
    grouped = {}

    keys.each do |key|
      suffix = "regular"

      if key.end_with?("#")
        suffix = "crop"
        dimensions = key[0..-2]
      elsif key.end_with?(">")
        suffix = "shrink"
        dimensions = key[0..-2]
      elsif key.end_with?("^")
        suffix = "cover"
        dimensions = key[0..-2]
      else
        dimensions = key
      end

      width_str, height_str = dimensions.split("x", 2)

      aspect_ratio = if width_str.nil? || width_str.empty?
        "*:#{height_str}"
      elsif height_str.nil? || height_str.empty?
        "#{width_str}:*"
      else
        width, height = width_str.to_i, height_str.to_i
        gcd = width.gcd(height)
        "#{width / gcd}:#{height / gcd}"
      end

      grouped[suffix] ||= {}
      grouped[suffix][aspect_ratio] ||= []
      grouped[suffix][aspect_ratio] << key
    end

    grouped.each do |suffix, ratios|
      # Sort aspect ratios by their product (width * height of simplified ratio)
      sorted_ratios = ratios.sort_by do |ratio, _|
        if ratio.include?("*")
          # Handle special cases with missing dimensions
          if ratio.start_with?("*:")
            ratio.split(":")[1].to_i
          elsif ratio.end_with?(":*")
            ratio.split(":")[0].to_i
          else
            0
          end
        else
          width, height = ratio.split(":").map(&:to_i)
          width * height
        end
      end

      grouped[suffix] = Hash[sorted_ratios]

      # Sort keys within each ratio by area
      grouped[suffix].each do |ratio, keys_array|
        grouped[suffix][ratio] = keys_array.sort_by do |key|
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

    grouped
  end

  private
    def before_render
      @readonly = !can_now?(:update, @file)
    end
end
