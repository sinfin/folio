# frozen_string_literal: true

class Folio::File::PublishedUsageCounter
  def self.count(file, site: nil)
    new(site:).count(file)
  end

  def self.sql_for_outer_file(site: nil)
    new(site:).count_sql(file_id_sql: "folio_files.id")
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

  def count_sql(file_id_sql:)
    usage_selects = direct_usage_selects(file_id_sql:) + atom_usage_selects(file_id_sql:)
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

  private
    attr_reader :site

    def direct_usage_selects(file_id_sql:)
      placement_types.filter_map do |placement_type|
        next if placement_type == "Folio::Atom::Base"

        klass = placement_type.safe_constantize
        next unless countable_record_class?(klass)

        usage_select_sql(file_id_sql:, placement_type:, klass:)
      end
    end

    def atom_usage_selects(file_id_sql:)
      return [] unless placement_types.include?("Folio::Atom::Base")

      atom_parent_types.filter_map do |placement_type|
        klass = placement_type.safe_constantize
        next unless countable_record_class?(klass)

        atom_usage_select_sql(file_id_sql:, placement_type:, klass:)
      end
    end

    def usage_select_sql(file_id_sql:, placement_type:, klass:)
      table_name = connection.quote_table_name(klass.table_name)

      <<~SQL.squish
        SELECT #{connection.quote(klass.base_class.name)} AS usage_record_type,
               #{table_name}.id AS usage_record_id
          FROM folio_file_placements
          JOIN #{table_name}
            ON #{table_name}.id = folio_file_placements.placement_id
         WHERE folio_file_placements.file_id = #{file_id_sql}
           AND folio_file_placements.placement_type = #{connection.quote(placement_type)}
           #{site_condition_sql(table_name, klass)}
           #{published_condition_sql(table_name, klass)}
      SQL
    end

    def atom_usage_select_sql(file_id_sql:, placement_type:, klass:)
      table_name = connection.quote_table_name(klass.table_name)

      <<~SQL.squish
        SELECT #{connection.quote(klass.base_class.name)} AS usage_record_type,
               #{table_name}.id AS usage_record_id
          FROM folio_file_placements
          JOIN folio_atoms folio_file_published_usage_atoms
            ON folio_file_published_usage_atoms.id = folio_file_placements.placement_id
           AND folio_file_placements.placement_type = 'Folio::Atom::Base'
          JOIN #{table_name}
            ON #{table_name}.id = folio_file_published_usage_atoms.placement_id
           AND folio_file_published_usage_atoms.placement_type = #{connection.quote(placement_type)}
         WHERE folio_file_placements.file_id = #{file_id_sql}
           #{site_condition_sql(table_name, klass)}
           #{published_condition_sql(table_name, klass)}
      SQL
    end

    def countable_record_class?(klass)
      return false unless klass && klass < ActiveRecord::Base
      return false if site && !klass.column_names.include?("site_id")

      true
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
