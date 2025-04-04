# frozen_string_literal: true

module Folio::Console::IndexHelper
  def index_header(opts = {})
    opts[:pagy] ||= @pagy
    opts[:pagy_options] ||= @pagy_options
    opts[:tabs] ||= index_tabs
    opts[:folio_console_merge] ||= @folio_console_merge
    opts[:csv] = controller.try(:folio_console_controller_for_handle_csv) if opts[:csv].nil?
    cell("folio/console/index/header", @klass, opts).show.html_safe
  end

  def catalogue(records, options = {}, &block)
    model = {
      records:,
      block:,
      klass: @klass,
      merge: @folio_console_merge,
    }.merge(options)

    model[:collection_actions] ||= controller.try(:folio_console_controller_for_catalogue_collection_actions) unless options[:no_collection_actions]

    cell("folio/console/catalogue", model).show.html_safe
  end
end
