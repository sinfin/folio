# frozen_string_literal: true

require "test_helper"
require "generators/folio/email_templates/email_templates_generator"

module Folio
  class Folio::EmailTemplatesGeneratorTest < Rails::Generators::TestCase
    tests Folio::EmailTemplatesGenerator
    destination Rails.root.join("tmp/generators")
    setup :prepare_destination

    # test "generator runs without errors" do
    #   assert_nothing_raised do
    #     run_generator ["arguments"]
    #   end
    # end
  end
end
