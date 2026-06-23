# frozen_string_literal: true

class Folio::Console::Files::Show::ThumbnailsComponent < Folio::Console::ApplicationComponent
  # Canonical ratios to which near values are snapped (group label).
  CANONICAL_RATIOS = %w[1:1 5:4 4:3 7:5 3:2 16:10 16:9 2:1 21:9 4:5 3:4 2:3 9:16].freeze
  # Relative tolerance for snapping (provisional; confirm with design).
  RATIO_TOLERANCE = 0.03

  def initialize(file:)
    @file = file
  end

  # Returns the canonical ratio label when the value is within RATIO_TOLERANCE of a
  # canonical ratio; otherwise returns the exact reduced-fraction label.
  def self.canonical_ratio_label(width, height)
    return "0:0" if width.zero? || height.zero?
    value = width.to_f / height
    best = CANONICAL_RATIOS.min_by do |r|
      cw, ch = r.split(":").map(&:to_i)
      (value - cw.to_f / ch).abs / (cw.to_f / ch)
    end
    bw, bh = best.split(":").map(&:to_i)
    return best if ((value - bw.to_f / bh).abs / (bw.to_f / bh)) <= RATIO_TOLERANCE
    gcd = width.gcd(height)
    "#{width / gcd}:#{height / gcd}"
  end

  def self.group_thumbnail_size_keys(keys)
    grouped = {}

    keys.each do |key|
      if key.end_with?("#")
        suffix = "crop"
        width_str, height_str = key[0..-2].split("x", 2)
        aspect_ratio = canonical_ratio_label(width_str.to_i, height_str.to_i)
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
