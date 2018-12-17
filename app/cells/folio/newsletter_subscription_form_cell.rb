# frozen_string_literal: true

module Folio
  class NewsletterSubscriptionFormCell < SavingFolioCell
    include SimpleForm::ActionViewExtensions::FormHelper
    include Engine.routes.url_helpers

    def newsletter_subscription
      @newsletter_subscription ||= (model || NewsletterSubscription.new)
    end

    def submitted
      !newsletter_subscription.new_record?
    end

    def submit_text
      return options[:submit_text] unless options[:submit_text].nil?
      t('.submit')
    end

    def message
      return options[:message] unless options[:message].nil?
      t('.message')
    end

    def button_class
      return options[:button_class] unless options[:button_class].nil?
      'btn'
    end

    def wrap_class
      base = 'folio-newsletter-subscription-form-wrap'
      base += ' folio-newsletter-subscription-form-submitted' if submitted
      base
    end

    def remember_option_keys
      [:placeholder, :submit_text, :message, :button_class]
    end
  end
end
