# frozen_string_literal: true

class Folio::Accounts::UnlocksController < Devise::UnlocksController
  include Folio::Accounts::DeviseControllerBase
end
