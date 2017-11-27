# frozen_string_literal: true

module Folio
  class NewsletterSubscriptionFormCell < FolioCell
    include SimpleForm::ActionViewExtensions::FormHelper
    include Engine.routes.url_helpers
    include ERB::Util

    def newsletter_subscription
      @newsletter_subscription ||= (model || NewsletterSubscription.new)
    end

    def submitted
      !newsletter_subscription.new_record?
    end

    def submit_text
      return options[:submit_text] if options[:submit_text]
      t('.submit')
    end

    def message
      return options[:message] if options[:message]
      t('.message')
    end

    def wrap_class
      base = 'folio-newsletter-subscription-form-wrap'
      base += ' folio-newsletter-subscription-form-submitted' if submitted
      base
    end

    def hidden_options
      [:placeholder, :submit_text, :message].map do |opt|
        value = options[opt]
        next unless value
        %{<input type="hidden" name="cell_options[#{opt}]" value="#{html_escape(value)}">}
      end.compact.join('')
    end
  end
end
