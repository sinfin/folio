# frozen_string_literal: true

class Dummy::Ui::MenuCell < ApplicationCell
  cache :show do
    model ? [model.id, model.updated_at] : "blank-ui-menu"
  end

  def show
    render if model.present?
  end

  def link_tag(menu_item, children = nil)
    class_name = "d-ui-menu__a"

    tag = {
      class: class_name,
      tag: :span,
    }

    if children.present?
      tag[:class] = "#{tag[:class]} #{class_name}--expandable"
    elsif path = menu_url_for(menu_item)
      tag[:tag] = :a
      tag[:href] = path
      tag[:target] = menu_item.open_in_new ? "_blank" : nil
    end

    tag
  end
end
