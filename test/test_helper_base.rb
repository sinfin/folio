# frozen_string_literal: true

require "rails/test_help"
require "capybara/rails"
require "capybara/minitest"
require "factory_bot"
require "vcr"
require "webmock/minitest"

require Folio::Engine.root.join("test/create_atom_helper")
require Folio::Engine.root.join("test/create_and_host_site")
require Folio::Engine.root.join("test/create_page_singleton")
require Folio::Engine.root.join("test/omniauth_helper")
require Folio::Engine.root.join("test/support/method_invoking_matchers_helper")

# Filter out Minitest backtrace while allowing backtrace from other libraries
# to be shown.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new

VCR.configure do |config|
  config.cassette_library_dir = "test/fixtures/vcr_cassettes"
  config.hook_into :webmock
end

FactoryBot.definition_file_paths << Folio::Engine.root.join("test/factories")

class ActiveSupport::TestCase
  parallelize
  include FactoryBot::Syntax::Methods
  include MethodInvokingMatchersHelper
end

class Cell::TestCase
  controller ApplicationController
  include FactoryBot::Syntax::Methods

  def action_controller_test_request(controller_class)
    request = ::ActionController::TestRequest.create(controller_class)

    if Rails.application.routes.default_url_options[:host]
      request.host = Rails.application.routes.default_url_options[:host]
    end

    request
  end
end

class Folio::CapybaraTest < ActionDispatch::IntegrationTest
  include Capybara::DSL
  include Capybara::Minitest::Assertions

  def teardown
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end
end

class Folio::Console::CellTest < Cell::TestCase
  controller Folio::Console::BaseController
end

class Folio::Console::BaseControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include Folio::Engine.routes.url_helpers

  def setup
    create_site
    @admin = create(:folio_account)
    sign_in @admin
  end

  def url_for(options = nil)
    super(options)
  rescue NoMethodError
    main_app.url_for(options)
  end

  def create_site
    create_and_host_site
  end
end

class Folio::ComponentTest < ViewComponent::TestCase
end
