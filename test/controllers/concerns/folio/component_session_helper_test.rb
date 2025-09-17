# frozen_string_literal: true

require "test_helper"

class Folio::ComponentSessionHelperTest < ActiveSupport::TestCase
  # Test component that includes the helper
  class TestComponent < ApplicationComponent
    include Folio::ComponentSessionHelper

    def initialize(require_session: false)
      @require_session = require_session
    end

    def before_render
      require_session_for_component!("test_component_reason") if @require_session
    end

    # Make method public for testing
    public :require_session_for_component!
  end

  # Mock controller for testing
  class MockController
    attr_accessor :component_session_requirements

    def require_session_for_component!(reason)
      @component_session_requirements ||= []
      @component_session_requirements << reason
    end
  end

  def setup
    @controller = MockController.new
    @component = TestComponent.new

    # Mock the controller method in the component
    @component.define_singleton_method(:controller) { @controller }
  end

  test "includes concern properly" do
    assert_includes TestComponent.ancestors, Folio::ComponentSessionHelper
    assert_respond_to @component, :require_session_for_component!
  end

  test "require_session_for_component! exists and handles missing helpers gracefully" do
    # Test that the method exists - it will log a warning but not crash
    # Since helpers isn't available in test context, it should gracefully handle this
    assert_nothing_raised do
      @component.require_session_for_component!("test_reason")
    end
  end

  test "require_session_for_component! handles missing controller gracefully" do
    # Component without helpers/controller context
    @component.define_singleton_method(:helpers) { nil }

    assert_nothing_raised do
      @component.require_session_for_component!("test_reason")
    end
  end

  test "require_session_for_component! handles controller without method gracefully" do
    # Mock helpers but controller without method
    helpers = Object.new
    helpers.define_singleton_method(:controller) { Object.new }
    helpers.define_singleton_method(:respond_to?) { |method| method == :controller }

    @component.define_singleton_method(:helpers) { helpers }

    assert_nothing_raised do
      @component.require_session_for_component!("test_reason")
    end
  end

  test "require_session_for_component! handles multiple calls gracefully" do
    # Mock helpers to avoid the ViewComponent error
    @component.define_singleton_method(:helpers) do
      # Return a mock that will trigger the fallback path
      Object.new
    end

    # Test that multiple calls don't cause errors
    assert_nothing_raised do
      @component.require_session_for_component!("reason_1")
      @component.require_session_for_component!("reason_2")
    end
  end
end
