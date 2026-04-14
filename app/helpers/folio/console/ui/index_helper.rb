# frozen_string_literal: true

module Folio::Console::Ui::IndexHelper
  def index_header(opts = {})
    kwargs = opts.merge(pagy: opts[:pagy] || @pagy,
                        pagy_options: opts[:pagy_options] || @pagy_options,
                        tabs: opts[:tabs] || try(:index_tabs),
                        csv: opts[:csv] || controller.try(:folio_console_controller_for_handle_csv))

    render(Folio::Console::Ui::Index::HeaderComponent.new(klass: @klass,
                                                          **kwargs))
  end

  def catalogue(records, options = {}, &block)
    merged = {
      records:,
      block:,
      klass: @klass,
      merge: @folio_console_merge,
      pagy: @pagy,
    }.merge(options)

    collection_actions = merged[:collection_actions]
    if merged[:no_collection_actions]
      collection_actions = nil
    elsif collection_actions.nil?
      collection_actions = controller.try(:folio_console_controller_for_catalogue_collection_actions)
    end

    render(Folio::Console::CatalogueComponent.new(
      records: merged[:records],
      block: merged[:block],
      klass: merged[:klass],
      merge: merged[:merge],
      pagy: merged[:pagy],
      ancestry: merged[:ancestry],
      allow_sorting: merged.fetch(:allow_sorting, true),
      js_data: merged[:js_data],
      collection_actions:,
      row_class_lambda: merged[:row_class_lambda],
      before_lambda: merged[:before_lambda],
      after_lambda: merged[:after_lambda],
      group_by_day: merged[:group_by_day],
      group_by_day_label_before: merged[:group_by_day_label_before],
      group_by_day_label_lambda: merged[:group_by_day_label_lambda],
      new_button: merged[:new_button],
      types: merged[:types],
      create_defaults_path: merged[:create_defaults_path],
      locals: merged[:locals] || {},
    ))
  end
end
