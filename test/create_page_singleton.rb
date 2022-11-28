# frozen_string_literal: true

def create_page_singleton(klass, attrs = {})
  page = create(:folio_page, { site: @site }.merge(attrs)).becomes!(klass)
  page.save!

  page
end
