# frozen_string_literal: true

class Folio::Console::Tiptap::OverlayComponent < Folio::Console::ApplicationComponent
  def data
    stimulus_controller("f-c-tiptap-overlay",
                        values: {
                          state: "closed",
                          origin: ENV["FOLIO_TIPTAP_DEV"] ? "*" : "",
                          edit_url: controller.folio.edit_node_console_api_tiptap_path,
                          save_url: controller.folio.save_node_console_api_tiptap_path,
                        },
                        action: {
                          "message@window" => "onWindowMessage",
                          "f-c-tiptap-overlay-form:submit" => "onFormSubmit",
                        })
  end
end
