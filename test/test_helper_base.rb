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
require Folio::Engine.root.join("test/support/tiptap_helper")

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
  require Folio::Engine.root.join("test/support/metadata_test_helpers")

  parallelize

  include FactoryBot::Syntax::Methods
  include MethodInvokingMatchersHelper
  include SitesHelper
  include TiptapHelper
  include MetadataTestHelpers

  def setup
    super
    Folio::Current.reset
  end

  def with_config(**config_overrides)
    original_values = {}

    # Store original values
    config_overrides.each do |key, value|
      original_values[key] = Rails.application.config.send(key)
      Rails.application.config.send("#{key}=", value) # TODO: Refactor to use stub, this vesion is not thread safe
    end

    yield
  ensure
    # Restore original values
    original_values.each do |key, value|
      Rails.application.config.send("#{key}=", value)
    end
  end

  def reset_folio_current(site_user_link)
    ::Folio::Current.reset
    ::Folio::Current.nillify_site_records
    ::Folio::Current.user = site_user_link.user

    ::Folio::Current.reset_ability!
  end
end

class Cell::TestCase # do not inherit from ActiveSupport::TestCase
  controller ApplicationController
  include FactoryBot::Syntax::Methods
  include SitesHelper

  require Folio::Engine.root.join("test/support/create_atom_helper")
  require Folio::Engine.root.join("test/support/create_test_tiptap_node_helper")
  require Folio::Engine.root.join("test/support/create_page_singleton_helper")

  attr_reader :site

  def setup
    Folio::Current.reset
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

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include Folio::Engine.routes.url_helpers
  attr_reader :site

  def sign_in(resource, scope: nil)
    Folio::Current.user = resource
    Folio::Current.site = @site
    super
  end

  def sign_out(user = nil)
    super if user
    Folio::Current.user = nil
    get destroy_user_session_path
  end

  require Folio::Engine.root.join("test/support/create_page_singleton_helper")
end

class Folio::CapybaraTest < ActionDispatch::IntegrationTest
  include Capybara::DSL
  include Capybara::Minitest::Assertions

  def teardown
    super
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end
end

class Folio::BaseControllerTest < ActionDispatch::IntegrationTest
  attr_reader :superadmin

  def setup
    super
    @site = create_site() if @site&.reload.nil?
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
  require Folio::Engine.root.join("test/support/create_test_tiptap_node_helper")
  require Folio::Engine.root.join("test/support/create_page_singleton_helper")
end

class Folio::Console::ComponentTest < Folio::ComponentTest
end

ActiveJob::Uniqueness.test_mode!
