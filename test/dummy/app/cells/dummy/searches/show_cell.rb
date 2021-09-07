# frozen_string_literal: true

class Dummy::Searches::ShowCell < ApplicationCell
  include Pagy::Frontend
  include SimpleForm::ActionViewExtensions::FormHelper

  def form(&block)
    opts = {
      url: controller.main_app.dummy_search_path,
      method: :get,
      html: { class: "d-searches-show__form h1" },
    }

    simple_form_for("", opts, &block)
  end

  def query_input(f)
    f.input :q,
            input_html: {
              class: "d-searches-show__input",
              value: params[:q],
              placeholder: t(".placeholder")
            },
            label: false,
            wrapper: false
  end
end
