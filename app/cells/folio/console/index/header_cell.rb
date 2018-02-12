# frozen_string_literal: true

class Folio::Console::Index::HeaderCell < FolioCell
  HIDDEN_FIELDS = [:by_parent, :by_published, :by_type, :by_tag].freeze

  def title
    model.model_name.human(count: 2)
  end

  def input
    text_field_tag :by_query, controller.params[:by_query],
                   class: 'form-control folio-console-by-query',
                   placeholder: t('.by_query')
  end

  def form(&block)
    opts = {
      method: :get,
      'data-auto-submit': true,
    }
    form_tag(controller.request.url, opts, &block)
  end
end
