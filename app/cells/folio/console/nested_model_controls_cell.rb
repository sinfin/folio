# frozen_string_literal: true

class Folio::Console::NestedModelControlsCell < FolioCell
  include Cocoon::ViewHelpers

  def f
    model
  end

  def handle_position?
    options[:only].blank? || options[:only] == :position
  end

  def handle_destroy?
    options[:only].blank? || options[:only] == :destroy
  end

  def class_name
    if options[:vertical]
      'folio-console-nested-model-controls-form-group--vertical'
    end
  end

  def btn_group_class_name
    if options[:vertical]
      'btn-group-vertical'
    else
      class_names << 'btn-group'
      class_names << 'mr-3' if handle_destroy?
      class_names.join(' ')
    end
  end

  def destroy_label
    if options[:vertical]
      content_tag(:i, '', class: 'fa fa-remove')
    else
      t('.destroy')
    end
  end
end
