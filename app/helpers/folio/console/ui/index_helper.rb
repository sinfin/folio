# frozen_string_literal: true

module Folio::Console::Ui::IndexHelper
  def index_header(opts = {}, &block)
    kwargs = opts.merge(pagy: opts[:pagy] || @pagy,
                        pagy_options: opts[:pagy_options] || @pagy_options,
                        tabs: opts[:tabs] || try(:index_tabs),
                        csv: opts[:csv] || controller.try(:folio_console_controller_for_handle_csv))

    component = Folio::Console::Ui::Index::HeaderComponent.new(klass: @klass,
                                                                **kwargs)

    if block_given?
      yield component
    end

    render(component)
  end

  def catalogue(records, options = {}, &block)
    model = {
      records:,
      block:,
      klass: @klass,
      merge: @folio_console_merge,
      pagy: @pagy,
    }.merge(options)

    model[:collection_actions] ||= controller.try(:folio_console_controller_for_catalogue_collection_actions) unless options[:no_collection_actions]

    cell("folio/console/catalogue", model).show.html_safe
  end
end
