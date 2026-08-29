# frozen_string_literal: true

class Folio::File::PublishedUsageCounter
  def self.count(file, site: nil)
    new(site:).count(file)
  end

  def self.records_sql(site: nil, file_ids_sql: nil)
    new(site:).records_sql(file_ids_sql:)
  end

  def self.preload(files, site:)
    new(site:).preload(files)
  end

  def initialize(site: nil)
    @site = site
  end

  def count(file)
    return 0 unless file&.id

    sql = count_sql(file_id_sql: connection.quote(file.id))
    return 0 if sql == "0"

    connection.select_value("SELECT #{sql}").to_i
  end

  def preload(files)
    persisted_files = files.select(&:persisted?)
    counts = counts_for_file_ids(persisted_files.map(&:id))

    persisted_files.each do |file|
      file.preload_published_usage_count_for_site(site, counts.fetch(file.id, 0))
    end
  end

  def count_sql(file_id_sql:)
    usage_selects = usage_selects(file_id_sql:, file_ids_sql: nil)
    return "0" if usage_selects.empty?

    <<~SQL.squish
      (
        SELECT COUNT(*)
          FROM (
            #{usage_selects.join(" UNION ")}
          ) folio_file_published_usage_records
      )
    SQL
  end

  def records_sql(file_ids_sql: nil)
    usage_selects = usage_selects(file_id_sql: nil, file_ids_sql:)
    if usage_selects.empty?
      return <<~SQL.squish
        SELECT NULL::bigint AS file_id,
               NULL::integer AS usage_record_type,
               NULL::bigint AS usage_record_id
         WHERE FALSE
      SQL
    end

    usage_selects.join(" UNION ")
  end

  private
    attr_reader :site

    def counts_for_file_ids(file_ids)
      return {} if file_ids.empty?

      quoted_ids = file_ids.map { |file_id| connection.quote(file_id) }.join(", ")
      sql = <<~SQL.squish
        SELECT folio_file_published_usage_records.file_id,
               COUNT(*) AS published_usage_count
          FROM (#{records_sql}) folio_file_published_usage_records
         WHERE folio_file_published_usage_records.file_id IN (#{quoted_ids})
         GROUP BY folio_file_published_usage_records.file_id
      SQL

      connection.select_rows(sql).to_h do |file_id, count|
        [file_id.to_i, count.to_i]
      end
    end

    def usage_selects(file_id_sql:, file_ids_sql:)
      direct_usage_selects(file_id_sql:, file_ids_sql:) +
        atom_usage_selects(file_id_sql:, file_ids_sql:)
    end

    def direct_usage_selects(file_id_sql:, file_ids_sql:)
      placement_types.filter_map do |placement_type|
        next if placement_type == "Folio::Atom::Base"

        klass = placement_type.safe_constantize
        next unless countable_record_class?(klass)

        usage_select_sql(file_id_sql:, file_ids_sql:, placement_type:, klass:)
      end
    end

    def atom_usage_selects(file_id_sql:, file_ids_sql:)
      return [] unless placement_types.include?("Folio::Atom::Base")

      atom_parent_types.filter_map do |placement_type|
        klass = placement_type.safe_constantize
        next unless countable_record_class?(klass)

        atom_usage_select_sql(file_id_sql:, file_ids_sql:, placement_type:, klass:)
      end
    end

    def usage_select_sql(file_id_sql:, file_ids_sql:, placement_type:, klass:)
      table_name = connection.quote_table_name(klass.table_name)

      <<~SQL.squish
        SELECT folio_file_published_usage_placements.file_id,
               #{usage_record_type_id(klass)} AS usage_record_type,
               #{table_name}.id AS usage_record_id
          FROM folio_file_placements folio_file_published_usage_placements
          JOIN #{table_name}
            ON #{table_name}.id = folio_file_published_usage_placements.placement_id
         WHERE folio_file_published_usage_placements.placement_type = #{connection.quote(placement_type)}
           #{file_condition_sql(file_id_sql:, file_ids_sql:)}
           #{site_condition_sql(table_name, klass)}
           #{published_condition_sql(table_name, klass)}
      SQL
    end

    def atom_usage_select_sql(file_id_sql:, file_ids_sql:, placement_type:, klass:)
      table_name = connection.quote_table_name(klass.table_name)

      <<~SQL.squish
        SELECT folio_file_published_usage_placements.file_id,
               #{usage_record_type_id(klass)} AS usage_record_type,
               #{table_name}.id AS usage_record_id
          FROM folio_file_placements folio_file_published_usage_placements
          JOIN folio_atoms folio_file_published_usage_atoms
            ON folio_file_published_usage_atoms.id = folio_file_published_usage_placements.placement_id
           AND folio_file_published_usage_placements.placement_type = 'Folio::Atom::Base'
          JOIN #{table_name}
            ON #{table_name}.id = folio_file_published_usage_atoms.placement_id
           AND folio_file_published_usage_atoms.placement_type = #{connection.quote(placement_type)}
         WHERE TRUE
           #{file_condition_sql(file_id_sql:, file_ids_sql:)}
           #{site_condition_sql(table_name, klass)}
           #{published_condition_sql(table_name, klass)}
      SQL
    end

    def countable_record_class?(klass)
      return false unless klass && klass < ActiveRecord::Base
      return false if site && !klass.column_names.include?("site_id")

      true
    end

    def file_condition_sql(file_id_sql:, file_ids_sql:)
      if file_id_sql
        return "AND folio_file_published_usage_placements.file_id = #{file_id_sql}"
      end
      return "" unless file_ids_sql

      "AND folio_file_published_usage_placements.file_id IN (#{file_ids_sql})"
    end

    def usage_record_type_id(klass)
      @usage_record_type_ids ||= {}
      @usage_record_type_ids[klass.base_class.name] ||= @usage_record_type_ids.length + 1
    end

    def site_condition_sql(table_name, klass)
      return "" unless site && klass.column_names.include?("site_id")

      "AND #{table_name}.site_id = #{connection.quote(site.id)}"
    end

    def published_condition_sql(table_name, klass)
      return "" unless klass.column_names.include?("published")

      "AND #{table_name}.published = TRUE"
    end

    def placement_types
      @placement_types ||= Folio::FilePlacement::Base.distinct.where.not(placement_type: nil).pluck(:placement_type)
    end

    def atom_parent_types
      @atom_parent_types ||= Folio::Atom::Base.distinct.where.not(placement_type: nil).pluck(:placement_type)
    end

    def connection
      ActiveRecord::Base.connection
    end
end
