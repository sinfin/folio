# frozen_string_literal: true

require "rails/test_help"
require "capybara/rails"
require "capybara/minitest"
require "factory_bot"
require "vcr"
require "webmock/minitest"


require Folio::Engine.root.join("test/support/omniauth_helper")
require Folio::Engine.root.join("test/support/action_mailer_test_helper")
require Folio::Engine.root.join("test/support/capybara_helper")


Rails.application.config.active_job.queue_adapter = :test

# Filter out Minitest backtrace while allowing backtrace from other libraries
# to be shown.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new

VCR.configure do |config|
  config.cassette_library_dir = "test/fixtures/vcr_cassettes"
  config.hook_into :webmock
end

FactoryBot.definition_file_paths << Folio::Engine.root.join("test/factories")

module ActiveJob::TestHelper
  include ActionMailerTestHelper
end

class ActiveSupport::TestCase
  require Folio::Engine.root.join("test/support/sites_helper")
  require Folio::Engine.root.join("test/support/method_invoking_matchers_helper")

  parallelize

  include FactoryBot::Syntax::Methods
  include MethodInvokingMatchersHelper
  include SitesHelper

  def setup
    super
    Folio::Current.original_reset
  end
end

class Cell::TestCase # do not inherit from ActiveSupport::TestCase
  controller ApplicationController
  include FactoryBot::Syntax::Methods
  include SitesHelper

  require Folio::Engine.root.join("test/support/create_atom_helper")

  attr_reader :site

  def setup
    Folio::Current.original_reset
    @site = get_any_site
  end

  # TODO: remove ?
  # def action_controller_test_request(controller_class)
  #   request = ::ActionController::TestRequest.create(controller_class)

  #   if Rails.application.routes.default_url_options[:host]
  #     request.host = Rails.application.routes.default_url_options[:host]
  #   end

  #   request
  # end
end

class Folio::Console::CellTest < Cell::TestCase
  controller Folio::Console::BaseController
end

class Folio::IntegrationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include Folio::Engine.routes.url_helpers
  attr_reader :site

  def sign_in(resource, scope: nil)
    Folio::Current.user = resource
    Folio::Current.site = @site
    super
  end

  def sign_out(user)
    super if user
    Folio::Current.user = nil
    get destroy_user_session_path
  end

  def create_page_singleton(klass, attrs = {})
    default_hash = @site ? { site: @site, locale: @site.locale } : {}

    page = create(:folio_page, default_hash.merge(attrs)).becomes!(klass)
    page.save!

    page
  end
end

class Folio::CapybaraTest < Folio::IntegrationTest
  include Capybara::DSL
  include Capybara::Minitest::Assertions

  def teardown
    super
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end
end

class Folio::BaseControllerTest < Folio::IntegrationTest
  attr_reader :superadmin

  def setup
    super
    @site = create_site() if @site.nil?
    host_site(@site)

    @superadmin = create(:folio_user, :superadmin)
    sign_in @superadmin
  end

  def teardown
    super
    sign_out(@superadmin)
  end

  def url_for(options = nil)
    super(options)
  rescue NoMethodError
    main_app.url_for(options)
  end
end

class Folio::Console::BaseControllerTest < Folio::BaseControllerTest
end


class Folio::ComponentTest < ViewComponent::TestCase
  require Folio::Engine.root.join("test/support/create_atom_helper")
end

class Folio::Console::ComponentTest < Folio::ComponentTest
end
