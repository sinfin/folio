module Folio
  module Console::FilteringHelper
    def filter_form(url = {}, opts = {}, &block)
      opts.reverse_merge!(id: 'filter-form', class: 'form', method: :get)
      form_tag(url, opts, &block)
    end

    def query_field(placeholder)
      text_field_tag :by_query, query,
                     class: 'form-control',
                     placeholder: placeholder
    end

    def custom_options_for_select(model, by_attribute, opts)
      # Eg.: opts = [['Potvrzené', ''], ['Nepotvrzené', 1]]
      selected = filter_params[by_attribute]
      select_tag by_attribute,
                 options_for_select(opts, selected),
                 class: 'form-control',
                 include_blank: false
    end
  end
end
