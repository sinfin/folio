# frozen_string_literal: true

class Folio::Console::Ui::WithIconComponent < Folio::Console::ApplicationComponent
  def initialize(message = nil, icon: nil, icon_options: {}, right_icon: nil, html_class: nil, tag: :span, data: nil, title: nil, hover: nil, block: false, href: nil, target: nil, html: nil)
    @message = message
    @icon = icon
    @icon_options = icon_options
    @right_icon = right_icon
    @html_class = html_class
    @tag = tag
    @data = data
    @title = title
    @hover = hover
    @block = block
    @href = href
    @target = target
    @html = html
  end

  def tag_name
    @href ? :a : @tag
  end

  def tag_attributes
    attrs = {}
    attrs[:class] = class_name
    attrs[:data] = @data if @data
    attrs[:title] = @title if @title
    attrs[:href] = @href if @href
    attrs[:target] = @target if @target
    attrs
  end

  def class_name
    classes = ["f-c-ui-with-icon"]
    classes << @html_class if @html_class
    classes << "f-c-ui-with-icon--hover-underline" if @hover == :underline
    classes << "d-flex" if @block
    classes.join(" ")
  end
end
