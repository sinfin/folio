# frozen_string_literal: true

# Opened by Folio::Console::StateCell's trigger for an aasm event declared with
# `email_modal: true`. The console user confirms the state change and, if they
# want, sends the record's e-mail address a message about it. The form posts
# straight to Folio::Console::Api::AasmController#event, which performs the
# transition and hands back the re-rendered state cell.
class Folio::Console::Aasm::EmailModalComponent < Folio::Console::ApplicationComponent
  include SimpleForm::ActionViewExtensions::FormHelper

  CLASS_NAME = "f-c-aasm-email-modal"

  def initialize
  end

  private
    def data
      stimulus_controller(CLASS_NAME,
                          action: {
                            "folioConsoleAasmEmailModalOpen" => "openFromEvent",
                          },
                          values: {
                            title: t(".title"),
                            send_email_label: t(".send_email_label"),
                          },
                          classes: %w[loading])
    end

    def form(&block)
      simple_form_for("", url: controller.folio.event_console_api_aasm_path, html: form_html, &block)
    end

    def form_html
      {
        class: "#{CLASS_NAME}__form",
        data: stimulus_action(submit: "onFormSubmit",
                              change: "onFormChange",
                              input: "onFormChange"),
      }
    end

    def key_hidden_field(f, key)
      f.hidden_field key,
                     value: nil,
                     class: "#{CLASS_NAME}__hidden",
                     data: stimulus_target("hidden")
    end

    def checkbox_input_html
      {
        class: "#{CLASS_NAME}__checkbox",
        checked: true,
        data: stimulus_target("checkbox"),
      }
    end

    def checkbox_label_html
      { data: stimulus_target("checkboxLabel") }
    end

    def subject_input_html
      {
        class: "#{CLASS_NAME}__subject",
        placeholder: t(".placeholders.subject"),
        data: stimulus_target("subject"),
      }
    end

    def text_input_html
      {
        class: "#{CLASS_NAME}__text",
        placeholder: t(".placeholders.text"),
        rows: 8,
        data: stimulus_target("text"),
      }
    end
end
