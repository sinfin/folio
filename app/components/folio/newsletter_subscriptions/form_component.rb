# frozen_string_literal: true

class Folio::NewsletterSubscriptions::FormComponent < ApplicationComponent
  include SimpleForm::ActionViewExtensions::FormHelper
  include ActionView::Helpers::FormOptionsHelper

  bem_class_name :persisted, :invalid

  def initialize(newsletter_subscription: nil, view_options: {})
    @newsletter_subscription = newsletter_subscription || Folio::NewsletterSubscription.new(email: "@")
    @view_options = view_options
    @persisted = @newsletter_subscription.persisted?
    @invalid = @newsletter_subscription.errors.present?
  end

  def form(&block)
    opts = {
      url: controller.folio.folio_api_newsletter_subscriptions_path,
      html: {
        class: "f-newsletter-subscriptions-form__form",
        id: nil,
        data: stimulus_action("onSubmit")
      },
    }

    simple_form_for(@newsletter_subscription, opts, &block)
  end

  def input(f)
    render(Dummy::Ui::InputWithButtonComponent.new(f:,
                                                   attribute: :email,
                                                   input_options: {
                                                     input_html: { class: "foo" }
                                                   },
                                                   button_model: {
                                                     type: :submit,
                                                     label: "foo",
                                                     size: :input,
                                                   }))
  end

  def data
    stimulus_controller("f-newsletter-subscriptions-form",
                        classes: %w[submitting persisted invalid])
  end

  def remember_option_keys
    [:placeholder, :submit_text, :message, :button_class, :input_label]
  end
end
