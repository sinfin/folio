# frozen_string_literal: true

module Folio::ApplicationHelper
  def public_page_title
    title = @public_page_title.presence || I18n.t("head.title.default")

    if title.present?
      base = [
        title,
        current_site.title,
      ]

      if Rails.application.config.folio_public_page_title_reversed
        base.reverse!
      end

      base.join(" #{I18n.t('head.title.separator')} ")
    else
      current_site.title
    end
  end

  def public_page_description
    text = @public_page_description.presence ||
           current_site.description.presence

    if text.present?
      truncate(strip_tags(text), length: 300)
    end
  end

  def public_page_canonical_url
    @public_page_canonical_url.presence
  end
end
