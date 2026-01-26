# frozen_string_literal: true

Folio::Site.class_eval do
  def folio_cache_version_keys
    %w[folio_sites]
  end
end
