# frozen_string_literal: true

require "test_helper"
require "generators/folio/scaffold/scaffold_generator"

module Folio
  class Folio::ScaffoldGeneratorTest < Rails::Generators::TestCase
    tests Folio::ScaffoldGenerator
    destination Rails.root.join("tmp/generators")
    setup :prepare_destination

    # test "generator runs without errors" do
    #   assert_nothing_raised do
    #     run_generator ["arguments"]
    #   end
    # end
  end
end
