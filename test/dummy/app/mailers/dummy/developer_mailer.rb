# frozen_string_literal: true

class Dummy::DeveloperMailer < ApplicationMailer
  def debug
    mail to: "foo@bar.baz"
  end
end
