# frozen_string_literal: true

Folio::Page.class_eval do
  def folio_cache_version_keys
    %w[folio_pages]
  end
end
