# frozen_string_literal: true

module Folio::Console::IndexHelper
  def index_thumb(cover, link = nil)
    return nil if cover.blank?

    src = cover.thumb(Folio::Console::FileSerializer::ADMIN_THUMBNAIL_SIZE).url
    img = image_tag(src, class: 'folio-console-index-table__img')
    if link
      link_to(img, link)
    else
      img
    end
  end

  def index_header(opts = {})
    opts[:pagy] ||= @pagy
    opts[:tabs] ||= index_tabs
    opts[:folio_console_merge] ||= @folio_console_merge
    cell('folio/console/index/header', @klass, opts).show.html_safe
  end
end
