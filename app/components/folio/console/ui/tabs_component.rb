# frozen_string_literal: true

class Folio::Console::Ui::TabsComponent < Folio::Console::ApplicationComponent
  ID_PREFIX = "tab-"

  def initialize(tabs:, remember: nil)
    @tabs = tabs
    @remember = remember
  end

  def count_class_name(color = nil)
    if color
      "f-c-ui-tabs__count--#{color}"
    end
  end

  def href(tab)
    tab[:href] || "##{ID_PREFIX}#{tab[:key]}"
  end

  def text_color_class_name(tab)
    if tab[:text_color]
      "f-c-ui-tabs__nav-link--color-#{tab[:text_color]}"
    end
  end

  def link_tag(tab)
    tag = { class: "nav-link f-c-ui-tabs__nav-link #{text_color_class_name(tab)}", role: "tab" }

    tag[:data] = stimulus_data(target: "link",
                               action: "onLinkClick")

    if tab[:href]
      tag[:tag] = :a
      tag[:href] = tab[:href]
      tag[:data][:href] = tab[:href]
    else
      tag[:tag] = :button
      tag[:type] = "button"
      tag[:data]["bs-toggle"] = "tab"
      tag[:data]["bs-target"] = "##{ID_PREFIX}#{tab[:key]}"
      tag[:data][:href] = "##{ID_PREFIX}#{tab[:key]}"
    end

    if tab[:active]
      tag[:class] += " active"
      tag["aria-selected"] = "true"
    end

    tag
  end

  def tab_pane(tab, &block)
    content_tag(:div, capture(&block), class: "tab-pane #{tab[:active] ? "active" : nil}", id: "#{ID_PREFIX}#{tab[:key]}")
  end

  def data
    stimulus_controller("f-c-ui-tabs",
                        values: {
                          remember: @remember || "",
                        })
  end
end
