# frozen_string_literal: true

class Folio::Console::TagsinputCell < FolioCell
  include SimpleForm::ActionViewExtensions::FormHelper

  def value
    model.object.tag_list.to_s
  end

  def input_html
    {
      class: 'folio-tagsinput',
      'data-tags': ActsAsTaggableOn::Tag.limit(1000).all.map(&:name),
    }
  end
end
