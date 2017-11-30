# frozen_string_literal: true

module Folio
  module ApplicationHelper
    def public_page_title
      [
        @title.presence || I18n.t('head.title.default'),
        I18n.t('head.title.prefix')
      ].compact.join(" #{I18n.t('head.title.separator')} ")
    end

    def public_page_description
      text = @description.presence || I18n.t('head.description')
      truncate(strip_tags(text), length: 300)
    end
  end
end
