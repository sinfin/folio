# frozen_string_literal: true

class Folio::Console::Layout::HeaderComponent < Folio::Console::ApplicationComponent
  def initialize(breadcrumbs_on_rails: nil, current_user_for_test: nil)
    @breadcrumbs_on_rails = breadcrumbs_on_rails
    @current_user_for_test = current_user_for_test
  end

  def log_out_path
    return nil unless Folio::Current.user

    @log_out_path ||= controller.try(:destroy_user_session_path) || controller.main_app.try(:destroy_user_session_path)
  rescue NoMethodError
  end

  def breadcrumb_position_class_name(i)
    if @breadcrumbs_on_rails && @breadcrumbs_on_rails.size - 2 == i
      "f-c-layout-header__breadcrumb--mobile"
    end
  end
end
