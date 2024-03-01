# frozen_string_literal: true

class Dummy::Searches::ShowComponent < ApplicationComponent
  include Pagy::Frontend
  include SimpleForm::ActionViewExtensions::FormHelper

  def form(&block)
    opts = {
      url: controller.main_app.dummy_search_path,
      method: :get,
      html: { class: "d-searches-show__form h1", id: nil },
    }

    simple_form_for("", opts, &block)
  end

  def query_input(f)
    f.input :q,
            input_html: {
              class: "d-searches-show__input",
              value: params[:q],
              placeholder: t(".placeholder"),
              autofocus: true,
              autocomplete: "off",
              id: nil,
              onfocus: "var dSearchesShowValue = this.value; this.value = ''; this.value = dSearchesShowValue",
            },
            label: false,
            wrapper: false
  end

  def data
    stimulus_controller("d-searches-show", values: {
      autocomplete_url: controller.main_app.autocomplete_dummy_search_path,
    })
  end
end
