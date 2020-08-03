# frozen_string_literal: true

class Folio::Console::Catalogue::RowCell < Folio::ConsoleCell
  include Folio::Console::FlagHelper

  def record
    model[:record]
  end

  def html
    return @html if @html
    @html = ''
    instance_eval(&model[:block])
    @html
  end

  def type
    attribute(:type, record.class.model_name.human)
  end

  def edit_link(attr = nil, &block)
    resource_link([:edit, :console, record], attr, &block)
  end

  def show_link(attr = nil, &block)
    resource_link([:console, record], attr, &block)
  end

  def attribute(name = nil, value = nil, &block)
    if block_given?
      @html += content_tag(:div, block.call(self.record), class: cell_class_name(name))
    elsif name
      @html += content_tag(:div, value || record.send(name), class: cell_class_name(name))
    end
  end

  def date(attr = nil)
    val = record.send(attr)
    val = l(val, format: :short) if val.present?
    attribute(attr, val)
  end

  def locale_flag
    attribute(:locale) do
      country_flag(record.locale) if record.locale
    end
  end

  def featured_toggle
    toggle(:featured)
  end

  def published_toggle
    toggle(:published)
  end

  def toggle(attr)
    attribute(attr) do
      if record.persisted?
        cell('folio/console/boolean_toggle', record, attribute: attr)
      end
    end
  end

  def actions(*act)
    attribute('') do
      cell('folio/console/index/actions', record, actions: act)
    end
  end

  private
    def resource_link(url_for_args, attr = nill)
      attribute(attr) do
        if record.persisted?
          if block_given?
            content = yield(record)
          elsif attr == :type
            content = record.class.model_name.human
          else
            content = record.public_send(attr)
          end

          url = controller.url_for(url_for_args)
          link_to(content, url)
        end
      end
    end

    def cell_class_name(attr = nil)
      if attr.present?
        "f-c-catalogue__cell f-c-catalogue__cell--#{attr}"
      else
        'f-c-catalogue__cell'
      end
    end
end
