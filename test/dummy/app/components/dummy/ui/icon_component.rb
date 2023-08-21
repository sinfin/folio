# frozen_string_literal: true

class Dummy::Ui::IconComponent < ApplicationComponent
  ICONS = YAML.load_file(::Rails.root.join("data/icons.yaml")).deep_symbolize_keys

  def initialize(name:, class_name: nil, width: nil, height: nil, top: nil, data: nil)
    @name = name
    raise "Unknown icon - #{@name}" if @name.blank? || !default_size

    @class_name = class_name
    @width = width
    @height = height
    @top = top
    @data = data
  end

  def default_size
    @default_size ||= ICONS[@name]
  end

  def class_names
    str = "d-ui-icon d-ui-icon--#{@name}"
    str += " #{@class_name}" if @class_name
    str
  end

  def style
    if @width
      width = option_size_to_str(@width)

      if @height
        height = option_size_to_str(@height)
      else
        height = "auto"
      end
    elsif @height
      width = "auto"
      height = option_size_to_str(@height)
    else
      width = "#{default_size[:width]}px"
      height = "#{default_size[:height]}px"
    end

    base = "width: #{width}; height: #{height}"

    if @top.is_a?(Numeric)
      "#{base}; position: relative; top: #{@top}px"
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
