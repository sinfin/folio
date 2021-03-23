# frozen_string_literal: true

class Dummy::Ui::IconCell < ApplicationCell
  def show
    content_tag(tag, "", class: class_names, href: options[:href])
  end

  def tag
    options[:href] ? :a : :span
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
