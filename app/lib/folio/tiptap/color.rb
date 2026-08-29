# frozen_string_literal: true

module Folio::Tiptap::Color
  HEX_FORMAT = /\A#[0-9a-f]{6}\z/

  HEX_INPUT_FORMAT = /\A#(?<hex>[0-9a-f]{3}|[0-9a-f]{6})\z/i
  FUNCTION_FORMAT = /\A(?<name>rgba?|hsla?)\((?<body>.*)\)\z/i
  NUMBER_FORMAT = /\A[+-]?(?:\d+(?:\.\d+)?|\.\d+)\z/
  HUE_FORMAT = /\A(?<value>[+-]?(?:\d+(?:\.\d+)?|\.\d+))(?<unit>deg|grad|rad|turn)?\z/i

  module_function

  def normalize(value)
    return unless value.is_a?(String)

    stripped = value.strip
    return if stripped.blank?

    normalize_hex(stripped) || normalize_function(stripped)
  end

  def valid?(value)
    value.blank? || (value.is_a?(String) && value.match?(HEX_FORMAT))
  end

  def normalize_hex(value)
    match = value.match(HEX_INPUT_FORMAT)
    return unless match

    hex = match[:hex].downcase
    hex = hex.each_char.map { |char| char * 2 }.join if hex.length == 3

    "##{hex}"
  end

  def normalize_function(value)
    match = value.match(FUNCTION_FORMAT)
    return unless match

    if match[:name].downcase.start_with?("rgb")
      normalize_rgb_function(match[:body])
    else
      normalize_hsl_function(match[:body])
    end
  end

  def normalize_rgb_function(body)
    components, alpha = parse_function_components(body)
    return unless components && opaque_alpha?(alpha)

    channels = components.map { |component| parse_rgb_channel(component) }
    return if channels.any?(&:nil?)

    format("#%02x%02x%02x", *channels)
  end

  def normalize_hsl_function(body)
    components, alpha = parse_function_components(body)
    return unless components && opaque_alpha?(alpha)

    hue = parse_hue(components[0])
    saturation = parse_percentage(components[1])
    lightness = parse_percentage(components[2])
    return if [hue, saturation, lightness].any?(&:nil?)

    format("#%02x%02x%02x", *hsl_to_rgb(hue, saturation / 100.0, lightness / 100.0))
  end

  def parse_function_components(body)
    if body.include?(",")
      parse_comma_components(body)
    else
      parse_space_components(body)
    end
  end

  def parse_comma_components(body)
    return if body.include?("/")

    parts = body.split(",").map(&:strip)
    return unless parts.size.in?([3, 4]) && parts.none?(&:blank?)

    [parts[0, 3], parts[3]]
  end

  def parse_space_components(body)
    parts = body.split("/", -1).map(&:strip)
    return if parts.size > 2

    color_parts = parts[0].split(/\s+/)
    alpha_parts = parts[1]&.split(/\s+/)
    return unless color_parts.size == 3
    return if alpha_parts && alpha_parts.size != 1

    [color_parts, alpha_parts&.first]
  end

  def parse_rgb_channel(component)
    stripped = component.strip

    if stripped.end_with?("%")
      percentage_to_channel(stripped.delete_suffix("%"))
    else
      number_to_channel(stripped)
    end
  end

  def percentage_to_channel(value)
    number = parse_number(value)
    return unless number&.between?(0, 100)

    (number * 255.0 / 100.0).round
  end

  def number_to_channel(value)
    number = parse_number(value)
    return unless number&.between?(0, 255)

    number.round
  end

  def opaque_alpha?(alpha)
    return true if alpha.nil?

    stripped = alpha.strip

    if stripped.end_with?("%")
      parse_number(stripped.delete_suffix("%")) == 100.0
    else
      parse_number(stripped) == 1.0
    end
  end

  def parse_hue(component)
    match = component.strip.match(HUE_FORMAT)
    return unless match

    hue_to_degrees(match[:value].to_f, (match[:unit] || "deg").downcase) % 360
  end

  def hue_to_degrees(value, unit)
    case unit
    when "deg"
      value
    when "grad"
      value * 0.9
    when "rad"
      value * 180.0 / Math::PI
    when "turn"
      value * 360.0
    end
  end

  def parse_percentage(component)
    stripped = component.strip
    return unless stripped.end_with?("%")

    number = parse_number(stripped.delete_suffix("%"))
    number if number&.between?(0, 100)
  end

  def parse_number(value)
    stripped = value.strip
    return unless stripped.match?(NUMBER_FORMAT)

    stripped.to_f
  end

  def hsl_to_rgb(hue, saturation, lightness)
    return achromatic_hsl_to_rgb(lightness) if saturation.zero?

    q = lightness < 0.5 ? lightness * (1 + saturation) : lightness + saturation - lightness * saturation
    p = 2 * lightness - q
    h = hue / 360.0

    [
      float_to_channel(hue_to_rgb(p, q, h + 1.0 / 3.0)),
      float_to_channel(hue_to_rgb(p, q, h)),
      float_to_channel(hue_to_rgb(p, q, h - 1.0 / 3.0))
    ]
  end

  def achromatic_hsl_to_rgb(lightness)
    channel = float_to_channel(lightness)
    [channel, channel, channel]
  end

  def hue_to_rgb(p, q, hue)
    hue += 1 if hue.negative?
    hue -= 1 if hue > 1

    return p + (q - p) * 6 * hue if hue < 1.0 / 6.0
    return q if hue < 1.0 / 2.0
    return p + (q - p) * (2.0 / 3.0 - hue) * 6 if hue < 2.0 / 3.0

    p
  end

  def float_to_channel(value)
    [[(value * 255).round, 0].max, 255].min
  end
end
