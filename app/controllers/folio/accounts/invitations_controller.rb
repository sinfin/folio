# frozen_string_literal: true

class Folio::Accounts::InvitationsController < Devise::InvitationsController
  layout "folio/console/devise"

  def after_accept_path_for(resource)
    console_root_path
  end
end
