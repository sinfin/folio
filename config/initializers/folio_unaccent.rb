# frozen_string_literal: true

# creates immutable (and indexable) version of unaccent function
# https://stackoverflow.com/questions/11005036/does-postgresql-support-accent-insensitive-collations/11007216#11007216
ActiveRecord::Migration.class_eval do
  def create_folio_unaccent
    sql = <<~SQL
      CREATE OR REPLACE FUNCTION public.folio_unaccent(text)
        RETURNS text AS
      $func$
      SELECT public.unaccent('public.unaccent', $1)
      $func$  LANGUAGE sql IMMUTABLE PARALLEL SAFE STRICT;
    SQL

    version = select_value("SHOW server_version").to_f
    sql = sql.gsub("PARALLEL SAFE ", "") if version <= 9.5

    execute sql
  end

  def drop_folio_unaccent
    execute <<~SQL
      DROP FUNCTION public.unaccent_immutable;
      DROP FUNCTION public.folio_unaccent;
    SQL
  end
end
