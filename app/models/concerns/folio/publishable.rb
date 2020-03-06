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
              "(#{table_name}.published_at IS NOT NULL AND #{table_name}.published_at <= ?)",
              true,
              Time.zone.now.change(sec: 0))
      }

      scope :published_or_admin, -> (admin) { admin ? all : published }

      scope :unpublished, -> {
        where("(#{table_name}.published != ? OR #{table_name}.published IS NULL) OR "\
              "(#{table_name}.published_at IS NULL OR #{table_name}.published_at > ?)",
              true,
              Time.zone.now.change(sec: 0))
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

      after_initialize :set_default_published_at
    end

    def published?
      published.present? &&
      published_at &&
      published_at <= Time.zone.now.change(sec: 0)
    end

    private

      def set_default_published_at
        self.published_at ||= Time.zone.now if new_record?
      end
  end
end
