# frozen_string_literal: true

class Dummy::Ui::HeaderSearchCell < ApplicationCell
  include SimpleForm::ActionViewExtensions::FormHelper

  class_name "d-ui-header-search", :expanded?

  def form(&block)
    opts = {
      url: controller.main_app.dummy_search_path,
      method: :get,
      html: { class: "d-ui-header-search__form", id: nil },
    }

    simple_form_for("", opts, &block)
  end

  def query_input(f)
    f.input :q,
            input_html: {
              class: "d-ui-header-search__input",
              value: params[:q],
              placeholder: t(".placeholder"),
              id: nil,
              autocomplete: "off",
            },
            label: false,
            wrapper: false
  end

  def expanded?
    params[:q].present?
  end
end
