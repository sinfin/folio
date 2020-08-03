# frozen_string_literal: true

class Folio::Console::CatalogueCell < Folio::ConsoleCell
  include Folio::Console::FlagHelper

  alias_method :old_cell, :cell

  def klass
    @klass ||= first_record.class
  end

  def first_record
    @first_record ||= model[:records].first
  end

  def header_html
    return @header_html if @header_html
    @header_html = ''
    instance_eval(&model[:block])
    @header_html
  end

  def method_missing(method_name, *arguments, &block)
    case method_name
    when :actions
      label = nil
    when :attribute, :edit_link, :show_link, :date, :toggle
      label = arguments.first
    when /_toggle\z/
      label = method_name.to_s.delete_suffix('_toggle')
    else
      label = method_name
    end

    if label && first_record.respond_to?(label)
      label = klass.human_attribute_name(label)
    end

    @header_html += content_tag(:div,
                                label,
                                class: "f-c-catalogue__header-cell f-c-catalogue__header-cell--#{method_name} f-c-catalogue__label")
  end
end
