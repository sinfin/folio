# frozen_string_literal: true

class Folio::Console::HtmlAutoFormat::ToggleComponent < Folio::Console::ApplicationComponent
  def initialize; end

  def preference_toggle_component
    Folio::Console::CurrentUsers::PreferenceToggleComponent.new(key: "html_auto_format",
                                                                javascript_key: "HtmlAutoFormat",
                                                                label: t(".label"),
                                                                class_name: "f-c-html-auto-format-toggle")
  end
end
