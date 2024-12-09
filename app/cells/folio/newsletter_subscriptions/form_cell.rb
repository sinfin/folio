# frozen_string_literal: true

class Folio::NewsletterSubscriptions::FormCell < Folio::ApplicationCell
  include SimpleForm::ActionViewExtensions::FormHelper

  def newsletter_subscription
    @newsletter_subscription ||= model || Folio::NewsletterSubscription.new(email: "@",
                                                                            tags: default_tags)
  end

  def form(&block)
    opts = {
      url: controller.folio.newsletter_subscriptions_path,
      html: { class: "f-newsletter-subscriptions-form__form", id: nil },
    }

    simple_form_for(newsletter_subscription, opts, &block)
  end

  def submitted
    !newsletter_subscription.new_record?
  end

  def submit_text
    return options[:submit_text] unless options[:submit_text].nil?
    t(".submit")
  end

  def message
    return options[:message] unless options[:message].nil?
    t(".message")
  end

  def button_class
    return options[:button_class] unless options[:button_class].nil?
    "btn btn-primary"
  end

  def wrap_class
    base = "f-newsletter-subscriptions-form"
    base += " f-newsletter-subscriptions-form--submitted" if submitted
    base
  end

  def remember_option_keys
    [:placeholder, :submit_text, :message, :button_class, :input_label]
  end

  def tags
    options[:tags]
  end

  def default_tags
    tags.map(&:first).first(1) if tags.present?
  end

  def input(f)
    f.input :email,
            as: :email,
            label: false,
            input_html: { class: "f-newsletter-subscriptions-form__input", id: nil }
  end
end
