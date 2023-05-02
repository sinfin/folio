# frozen_string_literal: true

class Folio::ConsoleCell < Folio::ApplicationCell
  include Folio::Console::CellsHelper
  include Folio::Cell::HtmlSafeFieldsFor

  delegate :safe_url_for,
           :through_aware_console_url_for,
           to: :controller

  def url_for(*args)
    controller.url_for(*args)
  end

  def admin_image(placement, opts = {})
    cell("folio/image",
         placement,
         opts.reverse_merge(size: Folio::Console::FileSerializer::ADMIN_THUMBNAIL_SIZE,
                            contain: true))
  end

  def sanitize_string(str)
    if str.present? && str.is_a?(String)
      ActionController::Base.helpers.sanitize(str, tags: [], attributes: [])
    else
      str
    end
  end

  def icon(name, opts = {})
    style = opts[:height] ? "font-size: #{opts[:height]}px" : nil

    content_tag(:i, name, class: "mi #{opts[:class]}", style:)
  end

  def preview_url_for(record)
    args = {}

    if record.respond_to?(:published?) && token = record.try(:preview_token)
      args[Folio::Publishable::PREVIEW_PARAM_NAME] = token
    end

    if record.respond_to?(:locale)
      args[:locale] = record.locale
    end

    url_for([record, args])
  rescue NoMethodError
  end
end
