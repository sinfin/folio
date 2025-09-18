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
