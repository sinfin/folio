# frozen_string_literal: true

class Folio::Users::EmailLogin::RequestComponent < Folio::ApplicationComponent
  def initialize(user:)
    @user = user
  end
end
