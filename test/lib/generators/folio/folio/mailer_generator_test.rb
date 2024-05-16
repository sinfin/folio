# frozen_string_literal: true

require "test_helper"
require "generators/folio/mailer/mailer_generator"

module Folio
  class Folio::MailerGeneratorTest < Rails::Generators::TestCase
    tests Folio::MailerGenerator
    destination Rails.root.join("tmp/generators")
    setup :prepare_destination

    # test "generator runs without errors" do
    #   assert_nothing_raised do
    #     run_generator ["arguments"]
    #   end
    # end
  end
end
