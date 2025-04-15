# frozen_string_literal: true

class Folio::ConsoleCell < Folio::ApplicationCell
  include Folio::Cell::HtmlSafeFieldsFor
  include Folio::Console::CellsHelper
  include Folio::Console::ReportsHelper
  include Folio::Console::PreviewUrlFor

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
end
