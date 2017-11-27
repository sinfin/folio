# frozen_string_literal: true

require 'test_helper'

class NewsletterSubscriptionFormCellTest < Cell::TestCase
  test 'show' do
    html = cell('newsletter_subscription_form').(:show)
    assert html.match /<p>/
  end
end
