# frozen_string_literal: true

class Folio::Console::FilePlacementListCell < FolioCell
  def show
    return nil if model.blank?
    return nil if model.file_placements.blank?
    render
  end

  def href(fp)
    placement = fp.placement
    if placement.is_a?(Folio::Node)
      controller.edit_console_node_path(placement.id)
    elsif placement.is_a?(Folio::Atom::Base)
      controller.edit_console_node_path(placement.placement)
    else
      nil
    end
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
