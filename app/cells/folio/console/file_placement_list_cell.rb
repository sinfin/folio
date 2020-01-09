# frozen_string_literal: true

class Folio::Console::FilePlacementListCell < Folio::ConsoleCell
  def show
    return nil if model.blank?
    return nil if model.file_placements.blank?
    render
  end

  def href(fp)
    placement = fp.placement
    if placement.is_a?(Folio::Page)
      controller.edit_console_page_path(placement.id)
    elsif placement.is_a?(Folio::Atom::Base)
      controller.edit_console_page_path(placement.placement)
    else
      controller.url_for([:edit, :console, placement])
    end
  rescue StandardError
    controller.url_for([:console, placement])
  rescue StandardError
    nil
  end

  def title(fp)
    t = fp.placement.try(:to_label) || fp.placement.try(:title)
    model_name = fp.placement.class.model_name.human

    if t.present?
      "#{model_name}: #{t}"
    else
      model_name
    end
  end

  def atom_placement(fp)
    return nil unless fp.placement.is_a?(Folio::Atom::Base)
    atom = fp.placement
    atom.placement.presence
  end
end
