# frozen_string_literal: true

class Folio::Console::NestedModelControlsCell < Folio::ConsoleCell
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
      if handle_destroy?
        'btn-group mr-3'
      else
        'btn-group'
      end
    end
  end

  def destroy_label
    if options[:vertical]
      content_tag(:i, '', class: 'fa fa-remove')
    else
      t('.destroy')
    end
  end

  def destroy_button_class_name
    'btn btn-danger folio-console-nested-model-destroy-button'
  end
end
