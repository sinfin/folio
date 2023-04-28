# frozen_string_literal: true

class Folio::Console::Layout::HeaderCell < Folio::ConsoleCell
  def log_out_path
    if options[:log_out_path]
      controller.send(options[:log_out_path])
    else
      if current_user
        router = controller
        router = router.main_app unless router.respond_to?(:destroy_user_session_url)
        router.destroy_user_session_url(only_path: false, host: Folio.site_for_crossdomain_devise.env_aware_domain)
      else
        controller.try(:destroy_account_session_path) || controller.main_app.try(:destroy_account_session_path)
      end
    end
  end

  def breadcrumb_position_class_name(i)
    if model[:breadcrumbs_on_rails].size - 2 == i
      "f-c-layout-header__breadcrumb--mobile"
    end
  end
end
