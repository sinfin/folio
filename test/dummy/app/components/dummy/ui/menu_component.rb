# frozen_string_literal: true

class Dummy::Ui::MenuComponent < ApplicationComponent
  def initialize(menu:)
    @menu = menu
  end

  def link_tag(menu_item, children = nil)
    class_name = "d-ui-menu__a"

    tag = {
      class: class_name,
      tag: :span,
    }

    if children.present?
      tag[:class] = "#{tag[:class]} #{class_name}--expandable"
    end

    if path = menu_url_for(menu_item)
      tag[:tag] = :a
      tag[:href] = path
      tag[:target] = menu_item.open_in_new ? "_blank" : nil
    end

    tag
  end
end
