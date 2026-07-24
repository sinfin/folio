# frozen_string_literal: true

class Folio::Console::Files::ThumbnailGroups::MainRatioGroups
  MAX_RELATIVE_DISTANCE = 0.15
  LANDSCAPE_RATIOS = %w[1:1 4:3 16:9 2:1].freeze
  PORTRAIT_RATIOS = %w[1:1 3:4 9:16 1:2].freeze
  RATIO_PATTERN = /\A\d+:\d+\z/

  def self.call(groups:, site:, ratio_proc:)
    new(groups:, site:, ratio_proc:).call
  end

  def self.default_ratio(ratio:, **)
    value = ratio_value(ratio)
    return ratio unless value

    candidates = value >= 1 ? LANDSCAPE_RATIOS : PORTRAIT_RATIOS
    canonical_ratio = candidates.min_by do |candidate|
      (Math.log(value / ratio_value(candidate))).abs
    end

    relative_distance = (value - ratio_value(canonical_ratio)).abs / ratio_value(canonical_ratio)
    relative_distance <= MAX_RELATIVE_DISTANCE ? canonical_ratio : ratio
  end

  def initialize(groups:, site:, ratio_proc:)
    @groups = groups
    @site = site
    @ratio_proc = ratio_proc
  end

  def call
    @groups.each_with_object({}) do |group, grouped|
      ratio = main_ratio(group)
      grouped[ratio] ||= group_data(ratio:)
      grouped[ratio]["sizes"] |= group.fetch("sizes")
      grouped[ratio]["ratios"] |= exact_ratios(group)
    end.values
  end

  private
    def self.ratio_value(ratio)
      return unless ratio.is_a?(String) && ratio.match?(RATIO_PATTERN)

      width, height = ratio.split(":").map(&:to_f)
      return if width.zero? || height.zero?

      width / height
    end

    private_class_method :ratio_value

    def main_ratio(group)
      ratio = @ratio_proc.call(ratio: group.fetch("ratio"),
                               sizes: group.fetch("sizes"),
                               site: @site)

      ratio.is_a?(String) && ratio.match?(RATIO_PATTERN) ? ratio : group.fetch("ratio")
    end

    def group_data(ratio:)
      {
        "ratio" => ratio,
        "ratio_label" => ratio.tr(":", "×"),
        "label" => nil,
        "sizes" => [],
        "ratios" => [],
      }
    end

    def exact_ratios(group)
      group.fetch("sizes").filter_map do |size|
        width, height = Folio::Console::Files::ThumbnailGroups.parse_crop_key(size)
        next unless width && height

        gcd = width.gcd(height)
        "#{width / gcd}:#{height / gcd}"
      end
    end
end
