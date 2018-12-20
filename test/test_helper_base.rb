# frozen_string_literal: true

require 'rails/test_help'
require 'capybara/rails'
require 'capybara/minitest'
require 'cells'
require 'cells-rails'
require 'cells-slim'
require 'factory_bot'
require Folio::Engine.root.join('test/create_atom_helper')

# Filter out Minitest backtrace while allowing backtrace from other libraries
# to be shown.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new

class Cell::TestCase
  controller ApplicationController
  include FactoryBot::Syntax::Methods
end

class Folio::Console::CellTest < Cell::TestCase
  controller Folio::Console::BaseController
end

class ActionDispatch::IntegrationTest
  # Make the Capybara DSL available in all integration tests
  include Capybara::DSL
  # Make `assert_*` methods behave like Minitest assertions
  include Capybara::Minitest::Assertions

  # Reset sessions and driver between tests
  # Use super wherever this method is redefined in your individual test classes
  def teardown
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end
end

class Folio::Console::BaseControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include Folio::Engine.routes.url_helpers

  def setup
    create(:folio_site)
    @admin = create(:folio_admin_account)
    sign_in @admin
  end
end

ActiveSupport::TestCase.include FactoryBot::Syntax::Methods
