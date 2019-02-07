# frozen_string_literal: true

module Folio
  module Console::IndexHelper
    def index_thumb(cover, link = nil)
      return nil if cover.blank?

      src = cover.thumb(Folio::FileSerializer::ADMIN_THUMBNAIL_SIZE).url
      img = image_tag(src, class: 'folio-console-index-table__img')
      if link
        link_to(img, link)
      else
        img
      end
    end

    def index_show_for(collection, &block)
      return nil if collection.blank?

      empty = show_for(collection.first.class.new, &block).html_safe

      all = [empty] + collection.map do |item|
        show_for(item, &block).html_safe
      end
      content_tag(:div, all.join('').html_safe, class: 'f-c-show-for-index')
    end
  end
end
