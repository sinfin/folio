# frozen_string_literal: true

class Folio::NewsletterSubscriptions::FormComponent < Folio::ApplicationComponent
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

  def submit_text
    return @view_options[:submit_text] unless @view_options[:submit_text].nil?
    t(".submit")
  end

  def message
    return @view_options[:message] unless @view_options[:message].nil?
    t(".message")
  end

  def input(f)
    f.input :email,
            as: :email,
            label: false,
            input_html: { class: "f-newsletter-subscriptions-form__input", id: nil },
            wrapper_html: { class: "f-newsletter-subscriptions-form__group" }
  end

  def data
    stimulus_controller("f-newsletter-subscriptions-form",
                        classes: %w[submitting persisted invalid])
  end

  def remember_option_keys
    [:placeholder, :submit_text, :message, :button_class, :input_label]
  end
end
