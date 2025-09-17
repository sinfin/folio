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
    component = Folio::NewsletterSubscriptions::FormComponent.new

    # Test polymorphic API
    assert component.requires_session?
    assert_equal "newsletter_subscription_csrf_and_turnstile", component.session_requirement_reason

    # Test session requirement hash structure
    requirement = component.session_requirement
    assert_equal "newsletter_subscription_csrf_and_turnstile", requirement[:reason]
    assert requirement[:component].include?("FormComponent")
    assert_kind_of Time, requirement[:timestamp]
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

      render_inline(Folio::NewsletterSubscriptions::FormComponent.new(view_options: view_options))

      assert_text "Custom Submit"
      assert_selector("input[placeholder='Custom placeholder']")
    end
  end
end
