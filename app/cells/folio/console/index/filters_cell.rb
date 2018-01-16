# frozen_string_literal: true

class Folio::Console::Index::FiltersCell < FolioCell
  include ActionView::Helpers::FormOptionsHelper

  def form(&block)
    opts = {
      method: :get,
      'data-auto-submit': true,
    }
    form_tag(controller.request.url, opts, &block)
  end

  def filtered?
    model.any? { |key| controller.params[key].present? }
  end

  def select(key)
    select_tag key, select_options(key),
               class: 'form-control',
               include_blank: false
  end

  def select_options(key)
    options_for_select(select_options_data(key), controller.params[key])
  end

  def select_options_data(key)
    case key
    when :by_parent
      options_by_parent

    when :by_published
      options_by_published

    when :by_type
      options_by_type

    else
      fail "Unknown key: #{key}"
    end
  end

  def options_by_parent
    [
      [t('.all_parents'), nil]
    ] + Folio::Node.original.roots.map { |n| [n.title, n.id] }
  end

  def options_by_published
    [
      [t('.all_nodes'), nil],
      [t('.published'), 'published'],
      [t('.unpublished'), 'unpublished'],
    ]
  end

  def options_by_type
    [
      [t('.all_types'), nil],
      [t('.page'), 'page'],
      [t('.category'), 'category'],
    ]
  end
end
