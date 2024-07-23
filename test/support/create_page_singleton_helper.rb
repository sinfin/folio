# frozen_string_literal: true

def create_page_singleton(klass, attrs = {})
  default_hash = @site ? { site: @site, locale: @site.locale } : {}

  page = create(:folio_page, default_hash.merge(attrs)).becomes!(klass)
  page.save!

  page
end
