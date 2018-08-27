# frozen_string_literal: true

module Folio
  module ApplicationHelper
    def public_page_title
      title = @public_page_title.presence || I18n.t('head.title.default')

      if title.present?
        base = [
          title,
          Site.instance.title,
        ]

        if Rails.application.config.folio_public_page_title_reversed
          base.reverse!
        end

        base.join(" #{I18n.t('head.title.separator')} ")
      else
        Site.instance.title
      end
    end

    def public_page_description
      text = @public_page_description.presence ||
             Site.instance.description.presence

      if text.present?
        truncate(strip_tags(text), length: 300)
      end
    end
  end
end
