# frozen_string_literal: true

class Folio::Console::Merges::Form::RowCell < Folio::ConsoleCell
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

  # def hidden_input
  #   f.hidden_field row_key, name: row_key, class: 'f-c-merges-form-row__value', id: nil
  # end

  def input(value: nil)
    input_html = { name: nil, id: nil, class: 'f-c-merges-form-row__input' }
    input_html[:value] = value unless value.nil?

    f.input row_key, input_html: input_html,
                     wrapper_html: { class: 'm-0' }
  end

  def original_input
    input
  end

  def duplicate_input
    input(value: merger.duplicate.send(row_key))
  end

  def radio(target)
    radio_button_tag(row_key,
                     target,
                     merger.targets[row_key] == target,
                     class: 'f-c-merges-form-row__radio',
                     id: nil)
  end
end
