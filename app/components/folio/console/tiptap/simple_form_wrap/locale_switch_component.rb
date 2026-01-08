# frozen_string_literal: true

class Folio::Console::Tiptap::SimpleFormWrap::LocaleSwitchComponent < Folio::Console::ApplicationComponent
  def initialize(base_field:, locales:)
    @base_field = base_field
    @locales = locales
  end

  def controller_data
    stimulus_controller("f-c-tiptap-simple-form-wrap-locale-switch",
                        values: {
                          baseField: @base_field
                        })
  end
end
