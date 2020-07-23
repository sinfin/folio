# frozen_string_literal: true

module Folio::Publishable
  module Basic
    extend ActiveSupport::Concern

    included do
      scope :published, -> { where(published: true) }
      scope :published_or_admin, -> (admin) { admin ? all : published }
      scope :unpublished, -> { where("#{table_name}.published != ? OR "\
                                     "#{table_name}.published IS NULL",
                                     true) }

      scope :by_published, -> (bool) {
        case bool
        when true, 'true'
          published
        when false, 'false'
          unpublished
        else
          all
        end
      }
    end

    def published?
      published.present?
    end
  end

  module WithDate
    extend ActiveSupport::Concern

    included do
      scope :published, -> {
        where("#{table_name}.published = ? AND "\
              "(#{table_name}.published_at IS NULL OR #{table_name}.published_at <= ?)",
              true,
              Time.zone.now)
      }

      scope :published_or_admin, -> (admin) { admin ? all : published }

      scope :unpublished, -> {
        where("(#{table_name}.published != ? OR #{table_name}.published IS NULL) OR "\
              "(#{table_name}.published_at IS NOT NULL AND #{table_name}.published_at > ?)",
              true,
              Time.zone.now)
      }

      scope :by_published, -> (bool) {
        case bool
        when true, 'true'
          published
        when false, 'false'
          unpublished
        else
          all
        end
      }
    end

    def published?
      if published.present?
        if published_at.present?
          published_at <= Time.zone.now
        else
          true
        end
      else
        false
      end
    end
  end

  module Within
    extend ActiveSupport::Concern

    included do
      scope :published, -> {
        where("#{table_name}.published = ? AND "\
              "(#{table_name}.published_from IS NULL OR #{table_name}.published_from <= ?) AND "\
              "(#{table_name}.published_until IS NULL OR #{table_name}.published_until >= ?)",
              true,
              Time.zone.now,
              Time.zone.now)
      }

      scope :published_or_admin, -> (admin) { admin ? all : published }

      scope :unpublished, -> {
        where("(#{table_name}.published != ? OR #{table_name}.published IS NULL) OR "\
              "(#{table_name}.published_from IS NOT NULL AND #{table_name}.published_from >= ?) OR "\
              "(#{table_name}.published_until IS NOT NULL AND #{table_name}.published_until <= ?)",
              true,
              Time.zone.now,
              Time.zone.now)
      }

      scope :by_published, -> (bool) {
        case bool
        when true, 'true'
          published
        when false, 'false'
          unpublished
        else
          all
        end
      }
    end

    def published?
      if published.present?
        if published_from.present? && published_from >= Time.zone.now
          return false
        end

        if published_until.present? && published_until <= Time.zone.now
          return false
        end

        true
      else
        false
      end
    end
  end
end
