# frozen_string_literal: true

class Folio::Console::TestModalCell < Folio::ConsoleCell
  include SimpleForm::ActionViewExtensions::FormHelper

  CLASS_NAME_BASE = "f-c-d-test-modal"
  CLASS_NAME = ".#{CLASS_NAME_BASE}"

  def show
    cell("folio/console/modal", class: CLASS_NAME_BASE,
                                body: render,
                                title: "test modal")
  end

  def form(&block)
    opts = { url: "./", method: :get }

    simple_form_for("", opts, &block)
  end

  def buttons_model
    [
      {
        type: :button,
        variant: :secondary,
        label: "Cancel",
        "data-bs-dismiss" => "modal",
      },
      {
        type: :submit,
        label: "Save",
      }
    ]
  end
end
