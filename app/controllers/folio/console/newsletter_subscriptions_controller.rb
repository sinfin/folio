# frozen_string_literal: true

class Folio::Console::NewsletterSubscriptionsController < Folio::Console::BaseController
  folio_console_controller_for "Folio::NewsletterSubscription", csv: true

  def index_filters
    {
      by_active: [true, false],
    }.compact
  end
end
