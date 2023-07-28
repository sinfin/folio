# frozen_string_literal: true

module Folio::Publishable
  PREVIEW_PARAM_NAME = :preview

  module Commons
    extend ActiveSupport::Concern

    included do
      before_validation :generate_preview_token

      scope :published, -> { folio_published }

      scope :unpublished, -> { folio_unpublished }

      scope :published_or_admin, -> (admin) { admin ? all : published }

      scope :published_or_preview_token, -> (preview_token) do
        if preview_token.present?
          where(preview_token:)
        else
          published
        end
      end

      scope :by_published, -> (bool) {
        case bool
        when true, "true"
          published
        when false, "false"
          unpublished
        else
          all
        end
      }
    end

    class_methods do
      def use_preview_tokens?
        true
      end
    end

    def published?
      folio_published?
    end

    def reset_preview_token!
      self.preview_token = nil
      generate_preview_token
      update_column(:preview_token, preview_token)
      self.preview_token
    end

    private
      def generate_preview_token
        return unless self.class.use_preview_tokens?
        return if preview_token.present?
        self.preview_token = SecureRandom.urlsafe_base64(8)
                                         .gsub(/-|_/, ("a".."z").to_a[rand(26)])
      end
  end

  module Basic
    extend ActiveSupport::Concern
    include Commons

    included do
      scope :folio_published, -> { where(published: true) }
      scope :folio_unpublished, -> {
        where("#{table_name}.published != ? OR "\
              "#{table_name}.published IS NULL",
              true)
      }
    end

    def folio_published?
      published.present?
    end
  end

  module WithDate
    extend ActiveSupport::Concern
    include Commons

    included do
      scope :folio_published, -> {
        where("#{table_name}.published = ? AND "\
              "(#{table_name}.published_at IS NULL OR #{table_name}.published_at <= ?)",
              true,
              Time.zone.now)
      }

      scope :folio_unpublished, -> {
        where("(#{table_name}.published != ? OR #{table_name}.published IS NULL) OR "\
              "(#{table_name}.published_at IS NOT NULL AND #{table_name}.published_at > ?)",
              true,
              Time.zone.now)
      }
    end

    class_methods do
      def cache_published_hash
        now = Time.zone.now
        sql = sanitize_sql(["SELECT md5(
                              array_to_string(
                                array(
                                  SELECT id
                                  FROM #{table_name}
                                  WHERE
                                    published = true AND
                                    (published_at BETWEEN ? AND ?)
                                ),
                              ',')
                            );",
                            now,
                            3.days.from_now])

        connection.query_value(sql)
      end
    end

    def folio_published?
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
    include Commons

    included do
      scope :folio_published, -> {
        where("#{table_name}.published = ? AND "\
              "(#{table_name}.published_from IS NULL OR #{table_name}.published_from <= ?) AND "\
              "(#{table_name}.published_until IS NULL OR #{table_name}.published_until >= ?)",
              true,
              Time.zone.now,
              Time.zone.now)
      }

      scope :folio_unpublished, -> {
        where("(#{table_name}.published != ? OR #{table_name}.published IS NULL) OR "\
              "(#{table_name}.published_from IS NOT NULL AND #{table_name}.published_from >= ?) OR "\
              "(#{table_name}.published_until IS NOT NULL AND #{table_name}.published_until <= ?)",
              true,
              Time.zone.now,
              Time.zone.now)
      }
    end

    class_methods do
      def cache_published_hash
        now = Time.zone.now
        sql = sanitize_sql(["SELECT md5(
                              array_to_string(
                                array(
                                  SELECT id
                                  FROM #{table_name}
                                  WHERE
                                    published = true AND
                                    (published_from IS NULL OR published_from < ?) AND
                                    (published_until IS NULL OR published_until > ?) AND
                                    (published_from > ? OR published_until < ?)
                                ),
                              ',')
                            );",
                            3.days.from_now,
                            3.days.ago,
                            now,
                            now])

        connection.query_value(sql)
      end
    end

    def folio_published?
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
