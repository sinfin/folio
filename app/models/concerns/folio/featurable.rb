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
              Time.zone.now.change(sec: 0),
              Time.zone.now.change(sec: 0))
      }

      folio_by_scopes_for :featured
    end

    def featured?
      featured.present? &&
      featured_from &&
      featured_from <= Time.zone.now.change(sec: 0) &&
      featured_until &&
      featured_until >= Time.zone.now.change(sec: 0)
    end
  end
end
