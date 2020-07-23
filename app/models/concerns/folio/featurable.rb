# frozen_string_literal: true

module Folio::Featurable
  module Basic
    extend ActiveSupport::Concern

    included do
      scope :featured, -> { where(featured: true) }

      folio_by_scopes_for :featured
    end
  end

  module Within
    extend ActiveSupport::Concern

    included do
      scope :featured, -> {
        where("#{table_name}.featured = ? AND "\
              "(#{table_name}.featured_from IS NULL OR #{table_name}.featured_from <= ?) AND "\
              "(#{table_name}.featured_until IS NULL OR #{table_name}.featured_until >= ?)",
              true,
              Time.zone.now,
              Time.zone.now)
      }

      folio_by_scopes_for :featured
    end

    def featured?
      if featured.present?
        if featured_from.present? && featured_from >= Time.zone.now
          return false
        end

        if featured_until.present? && featured_until <= Time.zone.now
          return false
        end

        true
      else
        false
      end
    end
  end
end
