# frozen_string_literal: true

module Folio::Console::UiHelper
  def folio_console_ui_button(opts)
    html = cell("folio/console/ui/button", opts).show
    html.html_safe if html
  end

  def folio_console_ui_image(placement, size = nil, **kwargs)
    render(Folio::Console::Ui::ImageComponent.new(placement:,
                                                  size: size || Folio::Console::FileSerializer::ADMIN_THUMBNAIL_SIZE,
                                                  **kwargs))
  end
end
