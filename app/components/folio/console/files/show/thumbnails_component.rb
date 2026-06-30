# frozen_string_literal: true

class Folio::Console::Files::Show::ThumbnailsComponent < Folio::Console::ApplicationComponent
  # Relative tolerance for proximity clustering of crop aspect ratios (provisional; confirm with design).
  RATIO_TOLERANCE = 0.04

  def initialize(file:)
    @file = file
  end

  # Crop aspect-ratio groups (proximity-clustered), keyed by reduced ratio label.
  def crop_ratios
    grouped["crop"] || {}
  end

  # All generated thumbnail size keys in a stable order: crop ratios first
  # (ascending), then the non-cropped "regular" sizes. Used for the
  # "All generated thumbnails" disclosure.
  def all_size_keys
    crop_keys = crop_ratios.values.flatten
    regular_keys = grouped.dig("regular", "regular") || []
    crop_keys + regular_keys
  end

  # Returns the "cleanest" reduced-fraction label for a bucket of [key, w, h] entries:
  # the one with the smallest numerator+denominator after gcd reduction.
  def self.cleanest_ratio_label(entries)
    entries.map { |(_k, w, h)|
      g = w.gcd(h)
      [(w / g) + (h / g), "#{w / g}:#{h / g}"]
    }.min_by(&:first).last
  end

  def self.group_thumbnail_size_keys(keys)
    grouped = {}

    # Collect crop entries: [key, ratio_float, w, h]
    crop_entries = []

    keys.each do |key|
      if key.end_with?("#")
        width_str, height_str = key[0..-2].split("x", 2)
        w = width_str.to_i
        h = height_str.to_i
        next if w.zero? || h.zero?
        crop_entries << [key, w.to_f / h, w, h]
      else
        grouped["regular"] ||= {}
        grouped["regular"]["regular"] ||= []
        grouped["regular"]["regular"] << key
      end
    end

    # Proximity cluster crop entries (ascending ratio, anchor = bucket's smallest ratio)
    unless crop_entries.empty?
      buckets = []
      crop_entries.sort_by { |(_k, r, _w, _h)| r }.each do |key, r, w, h|
        b = buckets.last
        if b && ((r - b[:anchor]) / b[:anchor]) <= RATIO_TOLERANCE
          b[:entries] << [key, w, h]
        else
          buckets << { anchor: r, entries: [[key, w, h]] }
        end
      end

      grouped["crop"] = {}
      buckets.each do |bucket|
        label = cleanest_ratio_label(bucket[:entries])
        grouped["crop"][label] ||= []
        grouped["crop"][label].concat(bucket[:entries].map(&:first))
      end
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
    def grouped
      @grouped ||= self.class.group_thumbnail_size_keys(@file.thumbnail_sizes.keys)
    end

    def before_render
      @readonly = !can_now?(:update, @file)
    end
end
