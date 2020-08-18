# frozen_string_literal: true

class Folio::Console::DropdownCell < Folio::ConsoleCell
  include Folio::Console::BootstrapHelper

  def show
    render if links.present?
  end

  def title
    model[:title]
  end

  def links
    model[:links]
  end

  def menu_align
    model[:menu_align] || :right
  end

  def class_name
    model[:class_name] || "btn btn-secondary"
  end
end
