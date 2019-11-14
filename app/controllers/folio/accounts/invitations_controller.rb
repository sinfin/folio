# frozen_string_literal: true

class Folio::Accounts::InvitationsController < Devise::InvitationsController
  def after_accept_path_for(resource)
    console_root_path
  end
end
