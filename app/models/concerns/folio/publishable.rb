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
              Time.now.change(sec: 0))
      }

      scope :published_or_admin, -> (admin) { admin ? all : published }

      scope :unpublished, -> {
        where("(#{table_name}.published != ? OR #{table_name}.published IS NULL) OR "\
              "(#{table_name}.published_at IS NULL OR #{table_name}.published_at > ?)",
              true,
              Time.now.change(sec: 0))
      }

      before_save :auto_publish_now, if: :published_changed?
    end

    def published?
      published.present? &&
      published_at &&
      published_at <= Time.now.change(sec: 0)
    end

    def auto_publish_now
      self.published_at = Time.now if published? && published_at.nil?
    end
  end
end
