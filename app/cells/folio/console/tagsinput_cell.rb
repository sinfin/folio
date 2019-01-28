# frozen_string_literal: true

class Folio::Console::TagsinputCell < Folio::ConsoleCell
  include SimpleForm::ActionViewExtensions::FormHelper

  def show
    model.input name, input_html: input_html,
                      wrapper_html: wrapper_html
  end

  def selected
    options[:selected] || model.object.tag_list
  end

  def name
    options[:name] || :tag_list
  end

  def collection
    options[:collection] || ActsAsTaggableOn::Tag.pluck(:name)
  end

  def allow_creation
    options[:disable_creation] ? nil : true
  end

  def input_html
    value = model.object.send(name).presence
    value = value.join(', ') if value.is_a?(Array)
    {
      class: 'folio-console-tagsinput',
      value: value,
    }
  end

  def wrapper_html
    {
      'data-allow-create': allow_creation,
      'data-collection': collection.join(', '),
    }
  end
end
