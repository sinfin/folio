# frozen_string_literal: true

module Dummy::CacheKeys
  extend ActiveSupport::Concern

  CACHE_KEY_TABLE_NAMES = %w[
    folio_files
    folio_menus
    folio_pages
    folio_private_attachments
    folio_sites
  ]

  CACHE_KEY_TABLE_NAMES_SQL_IN = CACHE_KEY_TABLE_NAMES.map { |tn| "'#{tn}'" }.join(",")

  CACHE_KEY_TABLE_NAMES_SQL = <<~SQL
    SELECT t.table_name, updated_at, count
    FROM (
      SELECT
        table_name,
        data_type,
        (xpath('/row/max/text()', query_to_xml(format('select max(%I) from %I.%I', column_name, table_schema, table_name), true, true, '')))[1]::text as updated_at,
        (xpath('/row/count/text()', query_to_xml(format('select count(%I) from %I.%I', column_name, table_schema, table_name), true, true, '')))[1]::text as count
      FROM
        information_schema.columns
      WHERE
        column_name = 'updated_at'
        AND
        table_schema = 'public'
        AND
        table_name IN (#{CACHE_KEY_TABLE_NAMES_SQL_IN})
    ) as t
    ORDER BY updated_at DESC NULLS LAST;
  SQL

  def cache_key_data
    @cache_key_data ||= ActiveRecord::Base.connection.execute(CACHE_KEY_TABLE_NAMES_SQL).to_a
  end

  def cache_key_counts
    @cache_key_counts ||= cache_key_data.map { |d| d["count"] }.join("-")
  end

  def cache_key_updated_at
    @cache_key_updated_at ||= cache_key_data[0]["updated_at"]
  end

  CACHE_KEY_BASE_TIMER = 5.seconds
  CACHE_KEY_BASE_KEY = "cache_key_base"

  def cache_key_base
    @cache_key_base ||= begin
      cached_hash = Rails.cache.read(CACHE_KEY_BASE_KEY)

      if !cached_hash || !cached_hash[:set_at] || cached_hash[:set_at] < CACHE_KEY_BASE_TIMER.ago
        cached_hash = {
          value: [
            ENV["CURRENT_RELEASE_COMMIT_HASH"],
            cache_key_updated_at,
            cache_key_counts,
            request.host,
          ],
          set_at: Time.zone.now,
        }
        Rails.cache.write(CACHE_KEY_BASE_KEY, cached_hash)
      end

      cached_hash[:value]
    end
  end

  included do
    helper_method :cache_key_base
  end
end
