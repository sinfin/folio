# frozen_string_literal: true

require "rails/generators/active_record/migration"

class Folio::PgSearchIndexMigrationGenerator < Rails::Generators::Base
  include ActiveRecord::Generators::Migration

  source_root File.expand_path("templates", __dir__)

  argument :model, type: :string
  argument :scope_name, type: :string

  SQL_REGEX = /WHERE \((.*) @@/

  attr_reader :table_name, :expression

  def generate_migration
    klass = model.constantize
    @table_name = klass.table_name

    sql = klass.send(scope_name, "foo").to_sql
    match = sql.match(SQL_REGEX)

    fail "no sql match found" if match.nil?

    @expression = match[1]

    index_migration_name = "add_#{scope_name}_index_to_#{@table_name}"
    migration_template "migration.rb", "db/migrate/#{index_migration_name}.rb"
  end
end
