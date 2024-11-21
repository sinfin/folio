# frozen_string_literal: true

class Folio::Users::PasswordsController < Devise::PasswordsController
  include Folio::Users::DeviseControllerBase

  skip_before_action :require_no_authentication, only: %i[edit]
  before_action :sign_out_before_entering, only: %i[edit]

  def create
    if Rails.application.config.folio_users_publicly_invitable &&
       params[:user] &&
       params[:user][:email].present? &&
       email_belongs_to_invited_pending_user?(params[:user][:email])
      controller = self.class.to_s.gsub("Passwords", "Invitations").constantize.new
      controller.request = request
      controller.response = response
      render plain: controller.process("create")
    else
      super
    end
  end

  def update
    super do |user|
      if user.errors.any? && !user.errors.attribute_names.any? { |an| an.to_s.include?("password") }
        user.save(validation: false) # so password is changed even for invalid user
        user.errors.clear
      end
    end
  end

  private
    def sign_out_before_entering
      sign_out(Folio::Current.user) if Folio::Current.user
    end
end
