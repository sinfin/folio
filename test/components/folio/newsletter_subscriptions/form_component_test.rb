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
end
