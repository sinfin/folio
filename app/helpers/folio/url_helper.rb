# frozen_string_literal: true

module Folio
  module UrlHelper
    def active_link_to(title, path, active = nil)
      klass = ' active' if active || is_link_active?(path)
      link_to(title, path, class: klass)
    end


    # https://github.com/comfy/active_link_to/blob/master/lib/active_link_to/active_link_to.rb
    def is_link_active?(path)
      path = Addressable::URI::parse(path).path
      path = Regexp.escape(path).chomp('/')
      original = request.original_fullpath
      !original.match(/^#{path}(\/.*|\?.*)?$/).blank?
    end

    def nested_page_path(page)
      path = [page]
      while page.parent
        path.unshift page.parent.translate
        page = page.parent
      end
      page_path(path)
    end
  end
end
