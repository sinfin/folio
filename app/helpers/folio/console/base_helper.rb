# frozen_string_literal: true

module Folio::Console::BaseHelper
  def icon(name, title = nil)
    classes = ["TODO"]
    i = %{<i class="#{classes.join(' ')}"></i>}
    [i, title].compact.join(" ").html_safe
  end

  def rendered_breadcrumbs
    if breadcrumbs.present?
      render_breadcrumbs(
        builder: Folio::Console::BootstrapBreadcrumbsBuilder
      )
    end
  end

  def barebone_layout_for_turbo_frame?
    return @barebone_layout_for_turbo_frame if defined?(@barebone_layout_for_turbo_frame)
    turbo_frame_request_header = request.headers["Turbo-Frame"]
    @barebone_layout_for_turbo_frame = turbo_frame_request_header.present? &&
                                       turbo_frame_request_header.starts_with?("folio-console-file-")
  end
end
