# frozen_string_literal: true

module Folio::Console::BaseHelper
  def icon(name, title = nil)
    classes = ['fa', "fa-#{name}"]
    classes << 'fa-mr' if title.present?
    i = %{<i class="#{classes.join(' ')}"></i>}
    [i, title].compact.join(' ').html_safe
  end

  def rendered_breadcrumbs
    if @breadcrumbs.present?
      render_breadcrumbs(
        builder: Folio::Console::BootstrapBreadcrumbsBuilder
      )
    end
  end
end
