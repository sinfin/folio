# frozen_string_literal: true

class Folio::Console::Files::Show::ThumbnailsComponent < Folio::Console::ApplicationComponent
  def initialize(file:)
    @file = file
  end

  def self.group_thumbnail_size_keys(keys)
    grouped = {}

    keys.each do |key|
      if key.end_with?("#")
        suffix = "crop"
        dimensions = key[0..-2]

        width_str, height_str = dimensions.split("x", 2)
        width, height = width_str.to_i, height_str.to_i
        gcd = width.gcd(height)
        aspect_ratio = "#{width / gcd}:#{height / gcd}"
      else
        suffix = "regular"
        aspect_ratio = "regular"
      end

      grouped[suffix] ||= {}
      grouped[suffix][aspect_ratio] ||= []
      grouped[suffix][aspect_ratio] << key
    end

    # Sort "regular" keys by area, with specific priority order
    if grouped["regular"] && grouped["regular"]["regular"]
      grouped["regular"]["regular"] = grouped["regular"]["regular"].sort_by do |key|
        dimensions = key.gsub(/[>^]$/, "")
        width_str, height_str = dimensions.split("x", 2)
        has_suffix = key.end_with?(">") || key.end_with?("^")

        if width_str.nil? || width_str.empty?
          # Height only (e.g., "x240") - group 2, sort by height
          [2, height_str.to_i]
        elsif height_str.nil? || height_str.empty?
          # Width only (e.g., "120x") - group 2, sort by width
          [2, width_str.to_i]
        elsif has_suffix
          # Complete dimensions with suffix (e.g., "2560x2048>") - group 3, sort by area
          [3, width_str.to_i * height_str.to_i]
        else
          # Complete dimensions without suffix - group 1, sort by area
          [1, width_str.to_i * height_str.to_i]
        end
      end
    end

    # Sort crop aspect ratios and their keys
    if grouped["crop"]
      sorted_ratios = grouped["crop"].sort_by do |ratio, _|
        width, height = ratio.split(":").map(&:to_i)
        width * height
      end

      grouped["crop"] = Hash[sorted_ratios]

      # Sort keys within each ratio by area
      grouped["crop"].each do |ratio, keys_array|
        grouped["crop"][ratio] = keys_array.sort_by do |key|
          dimensions = key.end_with?("#") ? key[0..-2] : key
          width_str, height_str = dimensions.split("x", 2)
          width_str.to_i * height_str.to_i
        end
      end
    end

    # Ensure order: crop first, then regular
    result = {}
    result["crop"] = grouped["crop"] if grouped["crop"]
    result["regular"] = grouped["regular"] if grouped["regular"]

    result
  end

  private
    def before_render
      @readonly = !can_now?(:update, @file)
    end
end
