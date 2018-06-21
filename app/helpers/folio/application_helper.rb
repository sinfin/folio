# frozen_string_literal: true

module Folio
  module ApplicationHelper
    def public_page_title
      title = @title.presence || I18n.t('head.title.default')

      if title.present?
        [
          title,
          Site.instance.title,
        ].join(" #{I18n.t('head.title.separator')} ")
      else
        Site.instance.title
      end
    end

    def public_page_description
      text = @description.presence || Site.instance.description.presence
      if text.present?
        truncate(strip_tags(text), length: 300)
      end
    end
  end
end
