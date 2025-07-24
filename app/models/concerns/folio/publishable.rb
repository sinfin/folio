# frozen_string_literal: true

module Folio::Publishable
  PREVIEW_PARAM_NAME = :preview

  module Commons
    extend ActiveSupport::Concern

    included do
      before_validation :generate_preview_token
      before_validation :set_published_date_automatically_if_needed

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

      def require_published_date_for_publishing?
        false
      end

      def set_published_date_automatically?
        require_published_date_for_publishing?
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

    def publish!(**kwargs)
      publish(**kwargs)
      save!
    end

    def unpublish!(**kwargs)
      unpublish(**kwargs)
      save!
    end

    private
      def generate_preview_token
        return unless self.class.use_preview_tokens?
        return if preview_token.present?
        self.preview_token = SecureRandom.urlsafe_base64(8)
                                         .gsub(/-|_/, ("a".."z").to_a[rand(26)])
      end

      def set_published_date_automatically_if_needed
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

    def publish(**kwargs)
      self.published = true
    end

    def unpublish(**kwargs)
      self.published = false
    end
  end

  module WithDate
    extend ActiveSupport::Concern
    include Commons

    included do
      scope :folio_published, -> {
        if require_published_date_for_publishing?
          where("#{table_name}.published = ? AND "\
                "(#{table_name}.published_at IS NOT NULL) AND (#{table_name}.published_at <= ?)",
                true,
                Time.current)
        else
          where("#{table_name}.published = ? AND "\
                "(#{table_name}.published_at IS NULL OR #{table_name}.published_at <= ?)",
                true,
                Time.current)
        end
      }

      scope :folio_unpublished, -> {
        if require_published_date_for_publishing?
          where("(#{table_name}.published != ? OR #{table_name}.published IS NULL) OR "\
                "(#{table_name}.published_at IS NULL OR #{table_name}.published_at > ?)",
                true,
                Time.current)
        else
          where("(#{table_name}.published != ? OR #{table_name}.published IS NULL) OR "\
                "(#{table_name}.published_at IS NOT NULL AND #{table_name}.published_at > ?)",
                true,
                Time.current)
        end
      }
    end

    class_methods do
      def cache_published_hash
        now = Time.current
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
          published_at <= Time.current
        else
          if self.class.require_published_date_for_publishing?
            false
          else
            true
          end
        end
      else
        false
      end
    end

    def publish(published_at: Time.current)
      self.published = true
      self.published_at = published_at
    end

    def unpublish(**kwargs)
      self.published = false
      # self.published_at = nil
    end

    private
      def set_published_date_automatically_if_needed
        return unless self.class.set_published_date_automatically?
        return if published != true
        return if published_at.present?
        self.published_at = Time.current
      end
  end

  module Within
    extend ActiveSupport::Concern
    include Commons

    included do
      scope :folio_published, -> {
        if require_published_date_for_publishing?
          where("#{table_name}.published = ? AND "\
                "(#{table_name}.published_from IS NOT NULL) AND (#{table_name}.published_from <= ?) AND "\
                "(#{table_name}.published_until IS NULL OR #{table_name}.published_until >= ?)",
                true,
                Time.current,
                Time.current)
        else
          where("#{table_name}.published = ? AND "\
                "(#{table_name}.published_from IS NULL OR #{table_name}.published_from <= ?) AND "\
                "(#{table_name}.published_until IS NULL OR #{table_name}.published_until >= ?)",
                true,
                Time.current,
                Time.current)
        end
      }

      scope :folio_unpublished, -> {
        if require_published_date_for_publishing?
          where("(#{table_name}.published != ? OR #{table_name}.published IS NULL) OR "\
                "(#{table_name}.published_from IS NULL OR #{table_name}.published_from >= ?) OR "\
                "(#{table_name}.published_until IS NOT NULL AND #{table_name}.published_until <= ?)",
                true,
                Time.current,
                Time.current)
        else
          where("(#{table_name}.published != ? OR #{table_name}.published IS NULL) OR "\
                "(#{table_name}.published_from IS NOT NULL AND #{table_name}.published_from >= ?) OR "\
                "(#{table_name}.published_until IS NOT NULL AND #{table_name}.published_until <= ?)",
                true,
                Time.current,
                Time.current)
        end
      }
    end

    class_methods do
      def cache_published_hash
        now = Time.current
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
        if self.class.require_published_date_for_publishing? && published_from.blank?
          return false
        end

        if published_from.present? && published_from >= Time.current
          return false
        end

        if published_until.present? && published_until <= Time.current
          return false
        end

        true
      else
        false
      end
    end

    def publish(published_from: nil, published_until: nil)
      self.published = true
      self.published_from = published_from
      self.published_until = published_until
    end

    def unpublish(**kwargs)
      self.published = false
      # self.published_from = nil
      # self.published_until = nil
    end

    private
      def set_published_date_automatically_if_needed
        return unless self.class.set_published_date_automatically?
        return if published != true
        return if published_from.present?
        self.published_from = Time.current
      end
  end
end
