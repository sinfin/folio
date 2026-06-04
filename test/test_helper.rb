# frozen_string_literal: true

require File.expand_path("../../test/dummy/config/environment.rb", __FILE__)
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../../test/dummy/db/migrate", __FILE__)]
ActiveRecord::Migrator.migrations_paths << File.expand_path("../../db/migrate", __FILE__)
Folio.enabled_packs.each do |pack_name|
  migrate_path = Folio::Engine.root.join("packs", pack_name.to_s, "db/migrate")
  ActiveRecord::Migrator.migrations_paths << migrate_path.to_s if migrate_path.exist?
end

require "test_helper_base"

FactoryBot.definition_file_paths << File.join(File.dirname(__FILE__), "factories")
FactoryBot.definition_file_paths << File.join(File.dirname(__FILE__), "factories_dummy")
FactoryBot.find_definitions

if ARGV.empty?
  Folio.enabled_packs.each do |pack_name|
    test_path = Folio::Engine.root.join("packs", pack_name.to_s, "test")
    Dir[test_path.join("**/*_test.rb")].each { |file| require file } if test_path.exist?
  end
end
