# frozen_string_literal: true

module Folio::ApplicationHelper
  def public_page_title
    title = @public_page_title.presence || I18n.t("head.title.default")

    if title.present?
      base = [
        title,
        public_page_site_title,
      ]

      if Rails.application.config.folio_public_page_title_reversed
        base.reverse!
      end

      base.join(" #{I18n.t('head.title.separator')} ")
    else
      public_page_site_title
    end
  end

  def public_page_description
    text = @public_page_description.presence ||
           public_page_site_description.presence

    if text.present?
      truncate(strip_tags(text), length: 300)
    end
  end

  def public_page_canonical_url
    @public_page_canonical_url.presence
  end

  def public_page_site_title
    current_site.title
  end

  def public_page_site_description
    current_site.description
  end
end
