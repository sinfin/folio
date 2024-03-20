# frozen_string_literal: true

class Folio::DeviseMailerPreview < ActionMailer::Preview
  def reset_password_instructions
    Folio::DeviseMailer.reset_password_instructions(Folio::User.last,
                                                    "RESET_PASSWORD_TOKEN").tap do |email|
      Premailer::Rails::Hook.perform(email)
    end
  end

  def invitation_instructions
    Folio::DeviseMailer.invitation_instructions(Folio::User.last,
                                                "INVITATION_TOKEN").tap do |email|
      Premailer::Rails::Hook.perform(email)
    end
  end

  def omniauth_conflict
    auth = Folio::Omniauth::Authentication.where.not(conflict_user_id: nil, conflict_token: nil).first

    Folio::DeviseMailer.omniauth_conflict(auth).tap do |email|
      Premailer::Rails::Hook.perform(email)
    end
  end
end
