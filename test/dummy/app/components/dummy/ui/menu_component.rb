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
      tag[:data] = stimulus_action(click: "onExpandableClick")
    end

    if path = menu_url_for(menu_item)
      tag[:tag] = :a
      tag[:href] = path
      tag[:target] = menu_item.open_in_new ? "_blank" : nil
    end

    tag
  end

  def menu_javascript_key
    if @menu
      "[#{@menu.id}, #{@menu.updated_at.to_i}]"
    else
      "null"
    end
  end
end
