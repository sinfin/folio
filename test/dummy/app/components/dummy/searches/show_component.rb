# frozen_string_literal: true

class Dummy::Searches::ShowComponent < ApplicationComponent
  include SimpleForm::ActionViewExtensions::FormHelper

  def initialize(search:)
    @search = search
  end

  def form(&block)
    opts = {
      url: controller.main_app.dummy_search_path,
      method: :get,
      html: {
        class: "d-searches-show__form h1",
        id: nil,
        data: stimulus_data(target: "form", action: "onFormSubmit")
      },
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
              data: stimulus_data(target: "input", action: { input: "onInputInput", focus: "onInputFocus" })
            },
            label: false,
            wrapper: false
  end

  def data
    stimulus_controller("d-searches-show", values: {
      loading: false,
    })
  end
end
