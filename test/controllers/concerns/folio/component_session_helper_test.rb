# frozen_string_literal: true

require "test_helper"

class Folio::ComponentSessionHelperTest < ActiveSupport::TestCase
  # Test component that includes the helper
  class TestComponent < ApplicationComponent
    include Folio::ComponentSessionHelper

    def initialize(require_session: false, session_reason: nil)
      @require_session = require_session
      @session_reason = session_reason
    end

    def requires_session?
      @require_session
    end

    def session_requirement_reason
      @session_reason || "test_component_reason"
    end
  end

  # Test component that doesn't require session
  class NoSessionComponent < ApplicationComponent
    include Folio::ComponentSessionHelper

    def requires_session?
      false
    end

    def session_requirement_reason
      "no_session_needed"
    end
  end

  def setup
    @component = TestComponent.new(require_session: true, session_reason: "test_csrf")
    @no_session_component = NoSessionComponent.new
  end

  test "includes concern properly" do
    assert_includes TestComponent.ancestors, Folio::ComponentSessionHelper
    assert_respond_to @component, :requires_session?
    assert_respond_to @component, :session_requirement_reason
    assert_respond_to @component, :session_requirement
  end

  test "requires_session? returns correct boolean" do
    assert @component.requires_session?
    assert_not @no_session_component.requires_session?
  end

  test "session_requirement_reason returns custom reason" do
    assert_equal "test_csrf", @component.session_requirement_reason
    assert_equal "no_session_needed", @no_session_component.session_requirement_reason
  end

  test "session_requirement returns hash with details" do
    requirement = @component.session_requirement

    assert_kind_of Hash, requirement
    assert_equal "test_csrf", requirement[:reason]
    assert_equal "#{@component.class.name}_atom", requirement[:component]
    assert_kind_of Time, requirement[:timestamp]
  end

  test "default session_requirement_reason when not overridden" do
    default_component = TestComponent.new
    assert_equal "test_component_reason", default_component.session_requirement_reason
  end

  test "session_requirement includes component class name" do
    requirement = @component.session_requirement
    expected_component = "Folio::ComponentSessionHelperTest::TestComponent_atom"
    assert_equal expected_component, requirement[:component]
  end

  test "session_requirement timestamp is recent" do
    requirement = @component.session_requirement
    assert requirement[:timestamp] > 1.second.ago
    assert requirement[:timestamp] <= Time.current
  end
end
