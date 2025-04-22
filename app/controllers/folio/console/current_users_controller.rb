# frozen_string_literal: true

class Folio::Console::CurrentUsersController < Folio::Console::BaseController
  def show
    @user = Folio::Current.user

    @public_page_title = t(".title")
    add_breadcrumb @public_page_title, folio.console_current_user_path
  end
end
