# frozen_string_literal: true

class Folio::Console::Layout::Sidebar::TitleCell < Folio::ConsoleCell
  THUMB_SIZE = "32x32#"

  def show
    render if active_item
  end

  def active_item
    @active_item ||= items.first
  end

  def items
    @items ||= begin
      ary = ::Rails.application.config.folio_console_sidebar_title_items.call(self) || default_items
      ary.sort_by { |i| i[:active] ? 0 : 1 }
    end
  end

  def default_items
    [
      {
        label: current_site.pretty_domain,
        href: controller.console_root_path,
        image: current_site.folio_console_sidebar_title_image_path || image_path("folio/console/sidebar-site-logo.svg"),
        active: true,
      }
    ]
  end

  def new_item
    @new_item ||= ::Rails.application.config.folio_console_sidebar_title_new_item.call(self)
  end
end
