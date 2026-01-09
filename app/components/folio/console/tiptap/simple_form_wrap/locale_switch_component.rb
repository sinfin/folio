# frozen_string_literal: true

class Folio::Console::Tiptap::SimpleFormWrap::LocaleSwitchComponent < Folio::Console::ApplicationComponent
  def initialize(attribute_names:, locales:)
    @attribute_names = attribute_names
    @locales = locales
  end

  def controller_data
    stimulus_controller("f-c-tiptap-simple-form-wrap-locale-switch")
  end

  def attribute_names_with_locales
    @attribute_names.zip(@locales).map do |attribute_name, locale|
      { attribute_name: attribute_name, locale: locale }
    end
  end
end
