# frozen_string_literal: true

class Folio::Console::Layout::Sidebar::SearchCell < Folio::ConsoleCell
  include SimpleForm::ActionViewExtensions::FormHelper

  def form(&block)
    opts = {
      url: controller.console_search_path,
      method: :get,
      html: { class: 'f-c-layout-sidebar-search__form' },
    }

    simple_form_for('', opts, &block)
  end

  def input(f)
    input_html = {
      placeholder: t('.placeholder'),
      class: 'f-c-layout-sidebar-search__input',
    }
    wrapper_html = { class: 'f-c-layout-sidebar-search__form-group' }
    f.input :sidebar_query, label: false,
                            input_html: input_html,
                            wrapper_html: wrapper_html
  end
end
