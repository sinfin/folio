# frozen_string_literal: true

module Folio
  class CsrfController < ActionController::Base
    # use ActionController::Base so that nothing else gets loaded in vain
    def show
      render plain: form_authenticity_token
    end
  end
end
