# frozen_string_literal: true

class Folio::Console::Ui::DropdownComponent < Folio::Console::ApplicationComponent
  def initialize(links:, menu_align: :left)
    @links = links
    @menu_align = menu_align
  end

  def cell_content_for_link(link)
    cell("folio/console/ui/with_icon",
         link[:label],
         href: link[:href],
         class: "dropdown-item #{"f-c-index-actions__link--disabled" if link[:disabled]}",
         icon: link[:icon],
         icon_options: link[:icon_options],
         block: true,
         data: link[:data],
         title: link[:title])
  end
end
