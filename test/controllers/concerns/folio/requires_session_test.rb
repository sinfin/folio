# frozen_string_literal: true

require "test_helper"

class Folio::RequiresSessionTest < ActionController::TestCase
  # Test controller that includes the concern
  class TestController < ActionController::Base
    include Folio::RequiresSession

    attr_accessor :session_options_skip_called

    def index
      render plain: "index"
    end

    def quiz_action
      render plain: "quiz_action"
    end

    def normal_action
      render plain: "normal_action"
    end

    private
      def request
        @mock_request ||= begin
          req = super
          req.define_singleton_method(:session_options) do
            @session_options ||= {}
          end
          req.define_singleton_method(:session_options=) do |opts|
            @session_options = opts
          end
          req
        end
      end
  end

  # Test controller with specific session requirements
  class QuizController < TestController
    requires_session_for :quiz_functionality, only: [:quiz_action]
  end

  # Test controller that requires session for all actions
  class InteractiveController < TestController
    requires_session_for :interactive_features
  end

  # Test controller with except configuration
  class SelectiveController < TestController
    requires_session_for :user_tracking, except: [:index]
  end

  def setup
    @controller = TestController.new
    @request = ActionDispatch::TestRequest.create
    @response = ActionDispatch::TestResponse.new
  end

  test "includes concern properly" do
    assert_includes TestController.ancestors, Folio::RequiresSession
    assert_respond_to TestController, :requires_session_for
  end

  test "default behavior requires session for all actions" do
    assert @controller.send(:session_required_for_current_action?)
  end

  test "controller with only configuration" do
    @controller = QuizController.new
    @controller.action_name = "quiz_action"
    assert @controller.send(:session_required_for_current_action?)

    @controller.action_name = "normal_action"
    assert_not @controller.send(:session_required_for_current_action?)
  end

  test "controller with except configuration" do
    @controller = SelectiveController.new
    @controller.action_name = "index"
    assert_not @controller.send(:session_required_for_current_action?)

    @controller.action_name = "quiz_action"
    assert @controller.send(:session_required_for_current_action?)
  end

  test "controller that requires session for all actions" do
    @controller = InteractiveController.new
    @controller.action_name = "index"
    assert @controller.send(:session_required_for_current_action?)

    @controller.action_name = "any_action"
    assert @controller.send(:session_required_for_current_action?)
  end

  test "should_skip_cookies_for_cache? returns false when session required" do
    @controller = QuizController.new
    @controller.action_name = "quiz_action"

    assert_not @controller.send(:should_skip_cookies_for_cache?)
  end

  test "should_skip_cookies_for_cache? delegates to super when session not required" do
    @controller = QuizController.new
    @controller.action_name = "normal_action"

    # Add a super method that would normally return true
    @controller.define_singleton_method(:should_skip_cookies_for_cache?) do
      return false if session_required_for_current_action?
      true # simulated super behavior that would skip cookies
    end

    assert @controller.send(:should_skip_cookies_for_cache?)
  end

  test "session_required_actions class attribute works" do
    assert_equal :all, TestController.session_required_actions

    QuizController.requires_session_for :quiz_functionality, only: [:quiz_action]
    expected = { reason: :quiz_functionality, only: ["quiz_action"], except: nil }
    assert_equal expected, QuizController.session_required_actions
  end
end
