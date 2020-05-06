# frozen_string_literal: true

require 'test_helper'
require 'generators/folio/index_migration/index_migration_generator'

module Folio
  class Folio::PgSearchIndexMigrationGeneratorTest < Rails::Generators::TestCase
    tests Folio::PgSearchIndexMigrationGenerator
    destination Rails.root.join('tmp/generators')
    setup :prepare_destination

    # test "generator runs without errors" do
    #   assert_nothing_raised do
    #     run_generator ["arguments"]
    #   end
    # end
  end
end
