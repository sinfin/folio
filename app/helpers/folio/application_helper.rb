# frozen_string_literal: true

module Folio
  module ApplicationHelper
    def public_page_title
      title = @title.presence || I18n.t('head.title.default')
      if title.present?
        [
          title,
          I18n.t('head.title.base'),
        ].join(" #{I18n.t('head.title.separator')} ")
      else
        I18n.t('head.title.base')
      end
    end

    def public_page_description
      text = @description.presence ||
             Site.current.description.presence ||
             I18n.t('head.description')
      truncate(strip_tags(text), length: 300)
    end
  end
end
