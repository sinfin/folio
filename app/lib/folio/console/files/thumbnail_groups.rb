# frozen_string_literal: true

class Folio::Console::Files::ThumbnailGroups
  GROUP_TYPES = %w[crop main_crop].freeze
  RATIO_TOLERANCE = 0.02

  def self.call(file:, site:)
    new(file:, site:).call
  end

  def self.find(file:, site:, group_type:, ratio:)
    return unless GROUP_TYPES.include?(group_type)

    call(file:, site:).fetch(group_type).find { |group| group["ratio"] == ratio }
  end

  def initialize(file:, site:)
    @file = file
    @site = site
  end

  def call
    groups = group_thumbnail_size_keys(@file.thumbnail_sizes.keys)
    groups["main_crop"] = MainRatioGroups.call(
      groups: groups.fetch("crop"),
      site: @site,
      ratio_proc: Rails.application.config.folio_console_files_thumbnail_groups_main_ratio_proc,
    )
    Rails.application.config.folio_console_files_thumbnail_groups_proc.call(groups:, site: @site)
  end

  private
    def group_thumbnail_size_keys(keys)
      grouped = {}
      crop_entries = []

      keys.each do |key|
        if key.end_with?("#")
          width_str, height_str = key[0..-2].split("x", 2)
          width = width_str.to_i
          height = height_str.to_i
          next if width.zero? || height.zero?

          crop_entries << [key, width.to_f / height, width, height]
        else
          grouped["regular"] ||= {}
          grouped["regular"]["regular"] ||= []
          grouped["regular"]["regular"] << key
        end
      end

      group_crop_entries!(grouped:, crop_entries:)
      sort_regular_entries!(grouped)
      sort_crop_entries!(grouped)

      {
        "crop" => grouped.fetch("crop", {}).map { |ratio, sizes| group_data(ratio:, sizes:) },
        "regular" => grouped.fetch("regular", {}).map { |ratio, sizes| group_data(ratio:, sizes:) },
      }
    end

    def group_crop_entries!(grouped:, crop_entries:)
      return if crop_entries.empty?

      buckets = []

      crop_entries.sort_by { |(_key, ratio, _width, _height)| ratio }.each do |key, ratio, width, height|
        gcd = width.gcd(height)
        clean_sum = (width / gcd) + (height / gcd)
        clean_ratio = (width / gcd).to_f / (height / gcd)
        label = "#{width / gcd}:#{height / gcd}"
        bucket = buckets.last

        if bucket && ((ratio - bucket[:clean_ratio]).abs / bucket[:clean_ratio]) <= RATIO_TOLERANCE
          bucket[:entries] << key

          if clean_sum < bucket[:clean_sum]
            bucket[:clean_sum] = clean_sum
            bucket[:clean_ratio] = clean_ratio
            bucket[:label] = label
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

    def sort_regular_entries!(grouped)
      return unless grouped.dig("regular", "regular")

      grouped["regular"]["regular"].sort_by! do |key|
        dimensions = key.gsub(/[>^]$/, "")
        width_str, height_str = dimensions.split("x", 2)
        has_suffix = key.end_with?(">") || key.end_with?("^")

        if width_str.nil? || width_str.empty?
          [2, height_str.to_i]
        elsif height_str.nil? || height_str.empty?
          [2, width_str.to_i]
        elsif has_suffix
          [3, width_str.to_i * height_str.to_i]
        else
          [1, width_str.to_i * height_str.to_i]
        end
      end
    end

    def sort_crop_entries!(grouped)
      return unless grouped["crop"]

      grouped["crop"] = grouped["crop"].sort_by do |ratio, _sizes|
        width, height = ratio.split(":").map(&:to_i)
        width * height
      end.to_h

      grouped["crop"].each_value do |sizes|
        sizes.sort_by! do |key|
          dimensions = key.delete_suffix("#")
          width_str, height_str = dimensions.split("x", 2)
          width_str.to_i * height_str.to_i
        end
      end
    end

    def group_data(ratio:, sizes:)
      {
        "ratio" => ratio,
        "ratio_label" => ratio.tr(":", "×"),
        "label" => nil,
        "sizes" => sizes,
      }
    end
end
