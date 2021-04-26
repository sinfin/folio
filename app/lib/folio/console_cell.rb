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
         opts.merge(size: Folio::Console::FileSerializer::ADMIN_THUMBNAIL_SIZE,
                    contain: true))
  end
end
