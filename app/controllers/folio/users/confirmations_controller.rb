# frozen_string_literal: true

class Folio::Users::ConfirmationsController < Devise::ConfirmationsController
  include Folio::Users::DeviseUserPaths
end
