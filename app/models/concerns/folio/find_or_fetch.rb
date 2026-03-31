# frozen_string_literal: true

module Folio::FindOrFetch
  extend ActiveSupport::Concern

  # @param model_class [Class] Active Record model class (+self+ from +find_or_fetch+)
  # @raise [ArgumentError] when +site:+ or +published: true+ is used but the model has no matching scope
  def self.validate_keyword_options!(model_class, site:, published:)
    if site && !model_class.respond_to?(:by_site)
      raise ArgumentError,
            "#{model_class.name} does not support :site (add `by_site` or omit :site)"
    end

    if published == true && !model_class.respond_to?(:published_or_preview_token)
      raise ArgumentError,
            "#{model_class.name} does not support :published (include Folio::Publishable or omit :published)"
    end
  end

  class_methods do
    def find_or_fetch(slug_or_id, published: nil, site: nil, preview_token: nil, with: nil)
      Folio::FindOrFetch.validate_keyword_options!(self, site:, published:)

      scope = all
      scope = scope.by_site(site) if site

      if published == true
        scope = scope.published_or_preview_token(preview_token)
      end

      scope = scope.where(with) if with.present?

      if scope.respond_to?(:friendly)
        scope.friendly.find(slug_or_id)
      else
        scope.find(slug_or_id)
      end
    end
  end
end
