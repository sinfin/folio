# frozen_string_literal: true

class Dummy::Ui::HeaderSearchComponent < ApplicationComponent
  def form(&block)
    opts = {
      url: controller.main_app.dummy_search_path,
      method: :get,
      html: { class: "d-ui-header-search__form", id: nil, data: stimulus_target("form") },
    }

    simple_form_for("", opts, &block)
  end

  def query_input(f)
    f.input :q,
            input_html: {
              class: "d-ui-header-search__input",
              placeholder: t(".placeholder"),
              id: nil,
              autocomplete: "off",
              data: stimulus_data(target: "input",
                                  action: {
                                    input: "debouncedOnInput",
                                    blur: "onInputBlur",
                                    keydown: "onKeydown"
                                  })
            },
            label: false,
            wrapper: false
  end

  def data
    stimulus_controller("d-ui-header-search", values: {
      autocomplete_url: controller.main_app.autocomplete_dummy_search_path,
    })
  end
end
