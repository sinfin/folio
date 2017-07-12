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

    # def state_select_options(model)
    #   opts = model.group(:state).count.map { |state, count|
    #     name = t("states.#{model.simple_name}.#{state}")
    #     [ name, state ]
    #   }
    #   options_for_select(opts, filter_params[:with_state])
    # end
    #
    # def state_filter_select(model)
    #   select_tag :with_state,
    #              state_select_options(model),
    #              class: 'form-control',
    #              include_blank: t("states.#{model.simple_name}.all")
    # end
  end
end
