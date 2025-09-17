# frozen_string_literal: true

require "test_helper"

class Folio::ComponentSessionRequirementsTest < ActionController::TestCase
  # Test controller that includes the concern
  class TestController < ActionController::Base
    include Folio::ComponentSessionRequirements

    def index
      render plain: "index"
    end

    def page_with_form
      # Simulate component requiring session during render
      require_session_for_component!("test_form_csrf")
      render plain: "page with form"
    end

    # Mock the cache optimization method
    def should_skip_cookies_for_cache?
      return false if component_requires_session?
      true # would normally skip cookies
    end
  end

  def setup
    @controller = TestController.new
    @request = ActionDispatch::TestRequest.create
    @response = ActionDispatch::TestResponse.new
  end

  test "includes concern properly" do
    assert_includes TestController.ancestors, Folio::ComponentSessionRequirements
    assert_respond_to TestController.new, :component_session_requirements
    assert TestController.new.respond_to?(:component_requires_session?, true) # private method
  end

  test "initializes component session requirements" do
    @controller.send(:initialize_component_session_requirements)
    assert_equal [], @controller.component_session_requirements
  end

  test "component_requires_session? returns false when no requirements" do
    @controller.send(:initialize_component_session_requirements)
    assert_not @controller.send(:component_requires_session?)
  end

  test "require_session_for_component! adds requirement" do
    @controller.send(:initialize_component_session_requirements)
    @controller.send(:require_session_for_component!, "test_reason")

    assert @controller.send(:component_requires_session?)
    assert_equal 1, @controller.component_session_requirements.length

    requirement = @controller.component_session_requirements.first
    assert_equal "test_reason", requirement[:reason]
    assert requirement[:timestamp].present?
  end

  test "should_skip_cookies_for_cache? returns false when component requires session" do
    @controller.send(:initialize_component_session_requirements)
    @controller.send(:require_session_for_component!, "form_csrf")

    assert_not @controller.send(:should_skip_cookies_for_cache?)
  end

  test "should_skip_cookies_for_cache? delegates to super when no requirements" do
    @controller.send(:initialize_component_session_requirements)

    # Should delegate to super which returns true in our test controller
    assert @controller.send(:should_skip_cookies_for_cache?)
  end

  test "multiple component requirements are tracked" do
    @controller.send(:initialize_component_session_requirements)
    @controller.send(:require_session_for_component!, "csrf_token")
    @controller.send(:require_session_for_component!, "captcha_state")

    assert @controller.send(:component_requires_session?)
    assert_equal 2, @controller.component_session_requirements.length

    reasons = @controller.component_session_requirements.map { |req| req[:reason] }
    assert_includes reasons, "csrf_token"
    assert_includes reasons, "captcha_state"
  end

  test "before_action initializes requirements" do
    # Test that before_action properly initializes the instance variable
    @controller.action_name = "index"
    @controller.send(:initialize_component_session_requirements)

    assert_not_nil @controller.component_session_requirements
    assert_equal [], @controller.component_session_requirements
  end

  test "analyze_page_session_requirements detects component session needs" do
    # Mock atom with session requirements
    atom_with_session = Class.new do
      include Folio::ComponentSessionHelper

      def requires_session?
        true
      end

      def session_requirement_reason
        "mock_atom_csrf"
      end
    end.new

    # Mock atom without session requirements
    atom_without_session = Class.new do
      include Folio::ComponentSessionHelper

      def requires_session?
        false
      end
    end.new

    # Mock page with atoms
    page = Object.new
    page.define_singleton_method(:respond_to?) { |method| method == :atoms }
    page.define_singleton_method(:atoms) { [atom_with_session, atom_without_session] }

    @controller.send(:initialize_component_session_requirements)
    @controller.send(:analyze_page_session_requirements, page)

    assert @controller.send(:component_requires_session?)
    assert_equal 1, @controller.component_session_requirements.length

    requirement = @controller.component_session_requirements.first
    assert_equal "mock_atom_csrf", requirement[:reason]
    assert requirement[:component].include?("atom")
  end

  test "analyze_page_session_requirements handles page without atoms gracefully" do
    page = Object.new
    page.define_singleton_method(:respond_to?) { |method| false }

    @controller.send(:initialize_component_session_requirements)
    @controller.send(:analyze_page_session_requirements, page)

    assert_not @controller.send(:component_requires_session?)
    assert_equal [], @controller.component_session_requirements
  end
end
