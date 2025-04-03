# frozen_string_literal: true

class Folio::DeviseMailerPreview < ActionMailer::Preview
  def reset_password_instructions
    Folio::DeviseMailer.reset_password_instructions(Folio::User.last,
                                                    "RESET_PASSWORD_TOKEN")
  end

  def invitation_instructions
    Folio::DeviseMailer.invitation_instructions(Folio::User.last,
                                                "INVITATION_TOKEN")
  end

  def confirmation_instructions
    Folio::DeviseMailer.confirmation_instructions(Folio::User.last,
                                                 "CONFIRMATION_TOKEN")
  end

  def omniauth_conflict
    auth = Folio::Omniauth::Authentication.where.not(conflict_user_id: nil, conflict_token: nil).first

    Folio::DeviseMailer.omniauth_conflict(auth)
  end
end
