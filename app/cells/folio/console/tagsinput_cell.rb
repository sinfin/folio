# frozen_string_literal: true

class Folio::Console::TagsinputCell < Folio::ConsoleCell
  include SimpleForm::ActionViewExtensions::FormHelper

  def show
    model.input name, input_html: input_html,
                      wrapper_html: wrapper_html
  end

  def selected
    options[:selected] || model.object.send(list_attribute_name)
  end

  def list_attribute_name
    if options[:tag_context]
      "#{options[:tag_context].to_s.singularize}_list"
    else
      :tag_list
    end
  end

  def tag_collection
    if options[:tag_context]
      base = ActsAsTaggableOn::Tag.for_context(:topics)
    else
      base = ActsAsTaggableOn::Tag.all
    end

    base.order(name: :asc).pluck(:name)
  end

  def name
    options[:name] || list_attribute_name
  end

  def collection
    options[:collection] || tag_collection
  end

  def allow_creation
    options[:disable_creation] ? nil : true
  end

  def input_html
    if options[:value]
      value = options[:value]
    else
      value = model.object.send(name).presence
      value = value.join(', ') if value.is_a?(Array)
    end

    (options[:input_html] || {}).merge(
      class: 'folio-console-tagsinput',
      value: value,
    )
  end

  def wrapper_html
    {
      'data-allow-create': allow_creation,
      'data-collection': collection.join(', '),
    }
  end
end
