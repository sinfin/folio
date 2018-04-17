# frozen_string_literal: true

class Folio::Console::TagsinputCell < FolioCell
  include SimpleForm::ActionViewExtensions::FormHelper

  def separator
    options[:separator] || ' '
  end

  def value
    options[:value] || model.object.tag_list.join(separator)
  end

  def name
    options[:name] || :tag_list
  end

  def values
    options[:values] || ActsAsTaggableOn::Tag.limit(1000).all.map(&:name)
  end

  def allow_creation
    !options[:disable_creation]
  end

  def input_html
    {
      class: 'folio-tagsinput',
      'data-tags': values.join(separator),
      'data-allow-create': allow_creation,
      'data-comma-separated': (separator =~ /,\s*/ ? 'true' : nil),
      value: value,
    }
  end
end
