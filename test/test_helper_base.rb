# frozen_string_literal: true

require "rails/test_help"
require "capybara/rails"
require "capybara/minitest"
require "factory_bot"
require Folio::Engine.root.join("test/create_atom_helper")
require Folio::Engine.root.join("test/create_page_singleton")
require Folio::Engine.root.join("test/omniauth_helper")

# Filter out Minitest backtrace while allowing backtrace from other libraries
# to be shown.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new

def create_and_host_site(key: nil, attributes: {})
  @site = create(key || Rails.application.config.folio_site_default_test_factory || :folio_site,
                 attributes)

  Rails.application.routes.default_url_options[:host] = @site.domain
  Rails.application.routes.default_url_options[:only_path] = false

  if self.respond_to?(:host!)
    host!(@site.domain)
  end

  @site
end

class ActiveSupport::TestCase
  parallelize
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

class Folio::Console::CellTest < Cell::TestCase
  controller Folio::Console::BaseController
end

class Folio::Console::BaseControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include Folio::Engine.routes.url_helpers

  def setup
    create_site
    @admin = create(:folio_admin_account)
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

ActiveSupport::TestCase.include FactoryBot::Syntax::Methods
