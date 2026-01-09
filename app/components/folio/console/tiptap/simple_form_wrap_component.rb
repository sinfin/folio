# frozen_string_literal: true

class Folio::Console::Tiptap::SimpleFormWrapComponent < Folio::Console::ApplicationComponent
  attr_reader :f

  def initialize(simple_form_model:, simple_form_options: {})
    @simple_form_model = simple_form_model
    @simple_form_options = simple_form_options

    class_names = []

    if @simple_form_options && @simple_form_options[:class].present?
      class_names += @simple_form_options[:class].split(" ")
    end

    class_names << "f-c-tiptap-simple-form-wrap__form"

    @simple_form_options[:html] ||= {}
    @simple_form_options[:html][:class] = class_names.join(" ")
  end

  def model_class
    model = @simple_form_model.is_a?(Array) ? @simple_form_model.last : @simple_form_model
    model.class
  end

  def folio_tiptap_locales
    model_class.folio_tiptap_locales
  end

  def all_tiptap_fields
    model_class.folio_tiptap_fields
  end

  def grouped_tiptap_fields_for_locale_switcher
    locales = folio_tiptap_locales
    return [] if locales.empty?

    locales.map do |base_field, locale_array|
      {
        attribute_names: locale_array.map { |locale| "#{base_field}_#{locale}" },
        locales: locale_array
      }
    end
  end

  def data
    stimulus_controller("f-c-tiptap-simple-form-wrap",
                        values: {
                          scrolled_to_bottom: false,
                        },
                        action: {
                          "f-input-tiptap:updateWordCount" => "updateWordCount",
                          "f-c-tiptap-simple-form-wrap-autosave-info:continueUnsavedChanges" => "onContinueUnsavedChanges",
                          "f-input-tiptap:tiptapContinueUnsavedChanges" => "onTiptapContinueUnsavedChanges",
                          "f-input-tiptap:tiptapAutosaveFailed" => "onTiptapAutosaveFailed",
                          "f-input-tiptap:tiptapAutosaveSucceeded" => "onTiptapAutosaveSucceeded",
                          "f-c-file-placements-multi-picker-fields:addToPicker" => "onAddToMultiPicker",
                          "f-c-file-placements-multi-picker-fields:hookOntoFormWrap" => "onMultiPickerHookOntoFormWrap",
                          "f-c-ui-tabs:shown" => "onTabsChange",
                          "f-c-tiptap-simple-form-wrap-locale-switch:attributeChanged" => "onAttributeChanged",
                        })
  end
end
