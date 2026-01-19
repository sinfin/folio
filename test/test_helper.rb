# frozen_string_literal: true

require File.expand_path("../../test/dummy/config/environment.rb", __FILE__)
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../../test/dummy/db/migrate", __FILE__)]
ActiveRecord::Migrator.migrations_paths << File.expand_path("../../db/migrate", __FILE__)

require "test_helper_base"

# Engine factories
FactoryBot.definition_file_paths << File.join(File.dirname(__FILE__), "factories")
# Dummy app factories
FactoryBot.definition_file_paths << Folio::Engine.root.join("test/dummy/test/factories")
FactoryBot.find_definitions

# Only load pack and dummy tests when running full suite (no ARGV arguments)
# When specific files are provided, Rails will handle loading them
if ARGV.empty?
  # Load tests from enabled packs
  Folio.enabled_packs.each do |pack_name|
    test_path = Folio::Engine.root.join("packs", pack_name.to_s, "test")
    Dir[test_path.join("**/*_test.rb")].each { |f| require f } if test_path.exist?
  end

  # Load dummy app tests
  Dir[Folio::Engine.root.join("test/dummy/test/**/*_test.rb")].each { |f| require f }
end
