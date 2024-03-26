# frozen_string_literal: true

class Folio::Console::Layout::HeaderCell < Folio::ConsoleCell
  def log_out_path
    if options[:log_out_path]
      controller.send(options[:log_out_path])
    else
      if try(:current_user)
        opts = {
          only_path: false,
          host: Folio.site_for_crossdomain_devise.try(:env_aware_domain)
        }.compact

        router = controller
        router = router.main_app unless router.respond_to?(:destroy_user_session_url)
        router.destroy_user_session_url(opts)
      else
        controller.try(:destroy_user_session_path) || controller.main_app.try(:destroy_user_session_path)
      end
    end
  end

  def breadcrumb_position_class_name(i)
    if model[:breadcrumbs_on_rails].size - 2 == i
      "f-c-layout-header__breadcrumb--mobile"
    end
  end
end
