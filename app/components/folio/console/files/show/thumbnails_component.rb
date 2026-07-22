# frozen_string_literal: true

class Folio::Console::Files::Show::ThumbnailsComponent < Folio::Console::ApplicationComponent
  # Relative tolerance for proximity clustering of crop aspect ratios.
  # A key joins a bucket when its ratio is within +-2 % of the bucket's
  # cleanest ratio (the member with the smallest reduced numerator+denominator).
  RATIO_TOLERANCE = 0.02

  def initialize(file:)
    @file = file
  end

  # Crop aspect-ratio groups, configurable by the host app per current site.
  def crop_groups
    thumbnail_groups["crop"]
  end

  def regular_groups
    thumbnail_groups["regular"]
  end

  def self.thumbnail_groups(file)
    groups = group_thumbnail_size_keys(file.thumbnail_sizes.keys)
    Rails.application.config.folio_console_thumbnail_groups_proc.call(groups:, site: Folio::Current.site)
  end

  def self.crop_group(file:, ratio:)
    thumbnail_groups(file).fetch("crop").find { |group| group["ratio"] == ratio }
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

    # Proximity cluster crop entries: ascending ratio; a bucket is anchored to
    # its cleanest member's exact ratio and re-anchors when a cleaner member joins.
    unless crop_entries.empty?
      buckets = []

      crop_entries.sort_by { |(_k, r, _w, _h)| r }.each do |key, r, w, h|
        g = w.gcd(h)
        clean_sum = (w / g) + (h / g)
        clean_ratio = (w / g).to_f / (h / g)
        label = "#{w / g}:#{h / g}"

        b = buckets.last

        if b && ((r - b[:clean_ratio]).abs / b[:clean_ratio]) <= RATIO_TOLERANCE
          b[:entries] << key

          if clean_sum < b[:clean_sum]
            b[:clean_sum] = clean_sum
            b[:clean_ratio] = clean_ratio
            b[:label] = label
          end
        else
          buckets << { clean_sum:, clean_ratio:, label:, entries: [key] }
        end
      end

      grouped["crop"] = {}

      buckets.each do |bucket|
        grouped["crop"][bucket[:label]] ||= []
        grouped["crop"][bucket[:label]].concat(bucket[:entries])
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

    {
      "crop" => grouped.fetch("crop", {}).map { |ratio, sizes| group_data(ratio:, sizes:) },
      "regular" => grouped.fetch("regular", {}).map { |ratio, sizes| group_data(ratio:, sizes:) },
    }
  end

  private
    def self.group_data(ratio:, sizes:)
      { "ratio" => ratio, "ratio_label" => ratio.tr(":", "×"), "label" => nil, "sizes" => sizes }
    end

    private_class_method :group_data

    def thumbnail_groups
      @thumbnail_groups ||= self.class.thumbnail_groups(@file)
    end

    def before_render
      @readonly = !can_now?(:update, @file)
    end
end
