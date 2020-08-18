# frozen_string_literal: true

require "test_helper"
require "generators/folio/console/cell/cell_generator"

module Folio
  class Folio::Console::CellGeneratorTest < Rails::Generators::TestCase
    tests Folio::Console::CellGenerator
    destination Rails.root.join("tmp/generators")
    setup :prepare_destination

    # test "generator runs without errors" do
    #   assert_nothing_raised do
    #     run_generator ["arguments"]
    #   end
    # end
  end
end
