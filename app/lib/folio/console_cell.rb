# frozen_string_literal: true

class Folio::ConsoleCell < Folio::ApplicationCell
  include Folio::Console::CellsHelper
  include Folio::Cell::HtmlSafeFieldsFor

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

  def safe_url_for(opts)
    controller.url_for(opts)
  rescue StandardError
  end

  def through_aware_console_url_for(record, action: nil, hash: nil, safe: false)
    through_record = if controller.try(:folio_console_controller_for_through)
      through_record_name = controller.folio_console_controller_for_through.constantize.model_name.element
      controller.instance_variable_get("@#{through_record_name}")
    end

    opts = []
    opts << action if action
    opts << :console
    opts << through_record if through_record
    opts << record
    opts << hash if hash

    if safe
      safe_url_for(opts)
    else
      url_for(opts)
    end
  end
end
