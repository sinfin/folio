# frozen_string_literal: true

class Folio::Console::NewsletterSubscriptionsController < Folio::Console::BaseController
  folio_console_controller_for "Folio::NewsletterSubscription", csv: true
end
