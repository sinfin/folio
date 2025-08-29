# frozen_string_literal: true

module Folio::ApplicationHelper
  include Folio::MarkdownHelper

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
    @public_page_canonical_url ||= if try(:request) && request.url
      request.url.split("?").first
    end


    @public_page_canonical_url.presence
  end

  def public_page_site_title
    @public_page_site_title || Folio::Current.site.title
  end

  def public_page_site_description
    Folio::Current.site.description
  end

  def public_page_keywords_array
    @public_page_keywords_array.presence
  end

  def can_now?(action, object = nil)
    controller.can_now?(action, object)
  end

  def true_user
    controller.true_user
  end

  # override!
  def l(object, **options)
    object = object.in_time_zone if object.respond_to?(:utc) # Time, DateTime, ActiveSupport::TimeWithZone
    I18n.localize(object, **options)
  end
end
