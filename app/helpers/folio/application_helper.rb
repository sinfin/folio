# frozen_string_literal: true

module Folio
  module ApplicationHelper
    def public_page_title
      [
        I18n.t('head.title.prefix'),
        @title.presence || I18n.t('head.title.default')
      ].compact.join(" #{I18n.t('head.title.separator')} ")
    end

    def public_page_description
      text = @description.presence || I18n.t('head.description')
      truncate(strip_tags(text), length: 1000)
    end
  end
end
