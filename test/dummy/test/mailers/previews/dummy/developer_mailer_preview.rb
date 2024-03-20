# frozen_string_literal: true

class Dummy::DeveloperMailerPreview < ActionMailer::Preview
  def debug
    Dummy::DeveloperMailer.debug.tap do |email|
      Premailer::Rails::Hook.perform(email)
    end
  end
end
