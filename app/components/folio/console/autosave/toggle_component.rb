# frozen_string_literal: true

class Folio::Console::Autosave::ToggleComponent < Folio::Console::ApplicationComponent
  def initialize(record:)
    @record = record
  end

  def render?
    @record.present? && @record.respond_to?(:folio_autosave_enabled?) && @record.folio_autosave_enabled?
  end

  def preference_toggle_component
    Folio::Console::CurrentUsers::PreferenceToggleComponent.new(key: "autosave",
                                                                javascript_key: "Autosave",
                                                                label: t(".label"),
                                                                class_name: "f-c-autosave-toggle")
  end
end
