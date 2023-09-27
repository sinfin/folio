# frozen_string_literal: true

class Folio::Console::Ui::TabsComponent < Folio::Console::ApplicationComponent
  ID_PREFIX = "tab-"

  def initialize(tabs:)
    @tabs = tabs
  end

  def count_class_name(color = nil)
    if color
      "f-c-ui-tabs__count--#{color}"
    end
  end

  def href(tab)
    tab[:href] || "##{ID_PREFIX}-#{tab[:key]}"
  end

  def link_tag(tab)
    tag = { class: "nav-link f-c-ui-tabs__nav-link", role: "tab" }

    if tab[:href]
      tag[:tag] = :a
      tag[:href] = tab[:href]
    else
      tag[:tag] = :button
      tag[:type] = "button"
      tag["data-bs-toggle"] = "tab"
      tag["data-bs-target"] = "##{ID_PREFIX}-#{tab[:key]}"
    end

    if tab[:active]
      tag[:class] += " active"
      tag["aria-selected"] = "true"
    end

    tag
  end

  def tab_pane(tab, &block)
    content_tag(:div, capture(&block), class: "tab-pane #{tab[:active] ? "active" : nil}", id: "#{ID_PREFIX}-#{tab[:key]}")
  end
end
