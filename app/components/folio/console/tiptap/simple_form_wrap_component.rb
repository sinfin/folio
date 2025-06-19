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
end
