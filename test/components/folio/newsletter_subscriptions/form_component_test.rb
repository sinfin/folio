# frozen_string_literal: true

require "test_helper"

class Folio::NewsletterSubscriptions::FormComponentTest < Folio::ComponentTest
  def test_render
    render_inline(Folio::NewsletterSubscriptions::FormComponent.new)

    assert_selector(".f-newsletter-subscriptions-form")

    view_options = {
      application_namespace: "Dummy",
      message: "message",
      submit_text: "submit",
      submit_icon: "chevron_right",
      submit_icon_height: 20,
      placeholder: "placeholder",
      button_class: "button",
      input_label: "label",
    }

    render_inline(Folio::NewsletterSubscriptions::FormComponent.new(view_options:))

    assert_selector(".f-newsletter-subscriptions-form")
  end

  def test_requires_session_for_component
    with_controller_class(ApplicationController) do
      # Mock the controller to track session requirements
      vc_test_controller.define_singleton_method(:require_session_for_component!) do |reason|
        @component_session_requirements ||= []
        @component_session_requirements << reason
      end

      render_inline(Folio::NewsletterSubscriptions::FormComponent.new)

      requirements = vc_test_controller.instance_variable_get(:@component_session_requirements)
      assert_includes requirements, "newsletter_subscription_csrf_and_turnstile"
    end
  end

  def test_renders_with_subscription_instance
    subscription = Folio::NewsletterSubscription.new(email: "test@example.com")
    render_inline(Folio::NewsletterSubscriptions::FormComponent.new(newsletter_subscription: subscription))

    assert_selector(".f-newsletter-subscriptions-form")
    assert_selector("input[value='test@example.com']")
  end

  def test_renders_with_view_options
    with_controller_class(ApplicationController) do
      view_options = {
        submit_text: "Custom Submit",
        placeholder: "Custom placeholder"
      }

      # Mock session requirement tracking
      vc_test_controller.define_singleton_method(:require_session_for_component!) do |reason|
        @component_session_requirements ||= []
        @component_session_requirements << reason
      end

      render_inline(Folio::NewsletterSubscriptions::FormComponent.new(view_options: view_options))

      assert_text "Custom Submit"
      assert_selector("input[placeholder='Custom placeholder']")

      # Verify session requirement was called
      requirements = vc_test_controller.instance_variable_get(:@component_session_requirements)
      assert_includes requirements, "newsletter_subscription_csrf_and_turnstile"
    end
  end
end
