# frozen_string_literal: true

class CreateFolioUnaccentFunction < ActiveRecord::Migration[5.2]
  # creates immutable (and indexable) version of unaccent function
  # https://stackoverflow.com/questions/11005036/does-postgresql-support-accent-insensitive-collations/11007216#11007216
  def up
    execute <<~SQL
      CREATE OR REPLACE FUNCTION public.unaccent_immutable(regdictionary, text)
        RETURNS text LANGUAGE c IMMUTABLE PARALLEL SAFE STRICT AS
      '$libdir/unaccent', 'unaccent_dict';

      CREATE OR REPLACE FUNCTION public.folio_unaccent(text)
        RETURNS text LANGUAGE sql IMMUTABLE PARALLEL SAFE STRICT AS
      $func$
      SELECT public.unaccent_immutable(regdictionary 'public.unaccent', $1)
      $func$;
    SQL
  end

  def down
    execute <<~SQL
      DROP FUNCTION public.unaccent_immutable;
      DROP FUNCTION public.folio_unaccent;
    SQL
  end
end
