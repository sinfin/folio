# frozen_string_literal: true

# Host-defined models are not patched by the record_cache railtie. To cache them with
# Identity Cache, include +IdentityCache+, declare +cache_index+ as required by the gem,
# and mirror the Ruby guard pattern used here (+published+, +site+, +with:+).
module Folio::RecordCache::BaseConcern
  extend ActiveSupport::Concern

  class_methods do
    def find_or_fetch(slug_or_id, published: nil, site: nil, preview_token: nil, with: nil)
      Folio::FindOrFetch.validate_keyword_options!(self, site:, published:)

      record = resolve_record_from_cache(slug_or_id, site)

      raise ActiveRecord::RecordNotFound, production_safe_message("Couldn't find #{name} with identifier=#{slug_or_id}") if record.nil?

      if site && record.respond_to?(:site_id) && record.site_id != site.id
        raise ActiveRecord::RecordNotFound, production_safe_message(
          "#{name}##{record.id} belongs to site #{record.site_id}, expected #{site.id}",
        )
      end

      if published == true && record.respond_to?(:published?)
        unless record.published? || (preview_token.present? && preview_token.to_s == record.preview_token.to_s)
          raise ActiveRecord::RecordNotFound, production_safe_message("#{name}##{record.id} found but not published")
        end
      end

      if with.present?
        with.each do |attr, value|
          unless record.public_send(attr).to_s == value.to_s
            raise ActiveRecord::RecordNotFound, production_safe_message(
              "#{name}##{record.id} #{attr}=#{record.public_send(attr).inspect}, expected #{value.inspect}",
            )
          end
        end
      end

      record
    end

    private
      def resolve_record_from_cache(slug_or_id, site)
        if slug_or_id.is_a?(Integer) || slug_or_id.to_s.match?(/\A\d+\z/)
          fetch(slug_or_id.to_i)
        elsif site && respond_to?(:fetch_by_slug_and_site_id)
          fetch_by_slug_and_site_id(slug_or_id.to_s, site.id)
        elsif respond_to?(:fetch_by_slug)
          fetch_by_slug(slug_or_id.to_s)
        else
          find(slug_or_id)
        end
      end

      def production_safe_message(detail)
        return detail unless Rails.env.production?

        "Couldn't find #{name} with the given criteria."
      end
  end
end
