# frozen_string_literal: true

class Dummy::DeveloperMailerPreview < ActionMailer::Preview
  def debug
    Dummy::DeveloperMailer.debug
  end
end
