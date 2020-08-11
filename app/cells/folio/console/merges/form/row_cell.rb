# frozen_string_literal: true

class Folio::Console::Merges::Form::RowCell < Folio::ConsoleCell
  class_name 'f-c-merges-form-row', :atoms?

  def f
    model[:f]
  end

  def row
    model[:row]
  end

  def row_key
    if model[:row].is_a?(Hash)
      model[:row][:key]
    else
      model[:row]
    end
  end

  def merger
    model[:merger]
  end

  def atoms?
    return @atoms unless @atoms.nil?
    @atoms = model[:row].is_a?(Hash) && model[:row][:as] == :atoms
  end

  def input(target:, value: nil)
    input_html = {
      name: nil,
      id: nil,
      class: 'f-c-merges-form-row__input',
      value: value
    }

    if row.is_a?(Hash)
      case row[:as]
      when :tags
        cell('folio/console/tagsinput', f, value: value.pluck(:name).join(', '),
                                           input_html: input_html).show
      when :publishable_and_featured
        cell('folio/console/publishable_inputs', f, no_input_ids: true,
                                                    no_input_names: true).show
      when :file_placement
        placement = merger.send(target).send(row[:key])
        cell('folio/console/file_placements/list', [placement]).show
      when :file_placements
        placements = merger.send(target).send(row[:key])
        cell('folio/console/file_placements/list', placements).show
      when :association
        cell('folio/console/merges/form/association',
             record: merger.send(target),
             reflection: merger.klass.reflect_on_association(row_key)).show
      end
    else
      f.input row_key, input_html: input_html,
                       wrapper_html: { class: 'm-0' }
    end
  end

  def original_input
    input(target: Folio::Merger::ORIGINAL,
          value: merger.original.try(row_key))
  end

  def duplicate_input
    input(target: Folio::Merger::DUPLICATE,
          value: merger.duplicate.try(row_key))
  end

  def radio(target)
    radio_button_tag("merge[#{row_key}]",
                     target,
                     merger.targets[row_key] == target,
                     class: 'f-c-merges-form-row__radio',
                     id: nil)
  end

  def atom_iframe(target)
    record = merger.send(target)
    src = controller.placement_preview_console_atoms_path(record.class.to_s,
                                                          record.id)
    content_tag(:iframe, '', class: 'f-c-merges-form-row__atoms-iframe',
                             src: src)
  end

  def title?
    if row.is_a?(Hash)
      case row[:as]
      when :file_placement, :file_placements
        true
      end
    end
  end
end
