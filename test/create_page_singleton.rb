# frozen_string_literal: true

def create_page_singleton(klass, attrs = {})
  page = create(:folio_page, { site: @site, locale: @site.locale }.merge(attrs)).becomes!(klass)
  page.save!

  page
end
