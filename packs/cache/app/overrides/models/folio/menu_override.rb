# frozen_string_literal: true

Folio::Menu.class_eval do
  def folio_cache_version_keys
    %w[folio_menus]
  end
end
