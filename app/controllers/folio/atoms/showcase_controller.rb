# frozen_string_literal: true

class Folio::Atoms::ShowcaseController < Folio::BaseController
  def show
    authenticate_account!
  end
end
