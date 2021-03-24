# frozen_string_literal: true

class Dummy::Ui::IconCell < ApplicationCell
  ICONS = YAML.load_file(::Rails.root.join('data/icons.yaml')).deep_symbolize_keys

  def show
    render if model.present? && default_size
  end

  def default_size
    @default_size ||= ICONS[model]
  end

  def class_names
    str = "d-ui-icon d-ui-icon--#{model}"
    str += " #{size_class_name}" if size_class_name
    str += " #{options[:class]}" if options[:class]
    str
  end

  def size_class_name
    if options[:size]
      "d-ui-icon--#{options[:size]}"
    end
  end
end
