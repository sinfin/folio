# frozen_string_literal: true

require 'test_helper'

class Folio::Console::NewsletterSubscriptionsControllerTest < Folio::Console::BaseControllerTest
  include Folio::Engine.routes.url_helpers

  test 'index' do
    get url_for([:console, Folio::NewsletterSubscription])
    assert_response :success
  end
end
