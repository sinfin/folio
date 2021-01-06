# frozen_string_literal: true

class Folio::Accounts::SessionsController < Devise::SessionsController
  include Folio::HasCurrentSite
end
