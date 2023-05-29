# frozen_string_literal: true

class Folio::Ui::IconCell < ApplicationCell
  ICONS = YAML.load_file(::Folio::Engine.root.join("data/folio_icons.yaml")).deep_symbolize_keys

  def show
    render if model.present? && default_size
  end

  def default_size
    @default_size ||= ICONS[model]
  end

  def class_names
    str = "f-ui-icon f-ui-icon--#{model}"
    str += " #{options[:class]}" if options[:class]
    str
  end

  def style
    if options[:width]
      width = option_size_to_str(options[:width])

      if options[:height]
        height = option_size_to_str(options[:height])
      else
        height = "auto"
      end
    elsif options[:height]
      width = "auto"
      height = option_size_to_str(options[:height])
    else
      width = "#{default_size[:width]}px"
      height = "#{default_size[:height]}px"
    end

    base = "width: #{width}; height: #{height}"

    if options[:top].is_a?(Numeric)
      "#{base}; position: relative; top: #{options[:top]}px"
    else
      base
    end
  end

  def option_size_to_str(val)
    if val.is_a?(Numeric)
      "#{val}px"
    else
      val
    end
  end

  def js_default_sizes
    ICONS.to_json
  end
end
