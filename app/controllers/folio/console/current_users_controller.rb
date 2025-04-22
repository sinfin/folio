# frozen_string_literal: true

class Folio::Console::CurrentUsersController < Folio::Console::BaseController
  before_action :set_user_and_public_page_title

  def show
  end

  def update_email
    if @user.update(params.require(:user).permit(:email))
      redirect_to folio.console_current_user_path, flash: { notice: t(".success") }
    else
      flash.now[:alert] = t(".failure")
      render :show
    end
  end

  def update_password
    password_keys = [:current_password, :password, :password_confirmation]

    user_params = params.require(:user)
                        .permit(*password_keys)

    password_keys.each do |key|
      next if user_params[key].present?
      @user.errors.add(key, :blank)
    end

    if @user.valid_password?(user_params[:current_password])
      if @user.update(password: user_params[:password], password_confirmation: user_params[:password_confirmation])
        bypass_sign_in @user
        redirect_to folio.console_current_user_path, flash: { notice: t(".success") }
        return
      end
    end

    flash.now[:alert] = t(".failure")
    render :show
  end

  private
    def set_user_and_public_page_title
      @user = Folio::Current.user

      @public_page_title = t("folio.console.current_users.show_component.title")

      add_breadcrumb @public_page_title, folio.console_current_user_path
    end
end
