# frozen_string_literal: true

class Folio::Console::ReactPickerCell < Folio::ConsoleCell
  include ActionView::Helpers::NumberHelper

  def f
    model
  end

  def placement_key
    options[:placement_key]
  end

  def title
    options[:title].presence ||
      f.object.class.human_attribute_name(placement_key)
  end

  def form_errors
    if f.object.errors.include?(placement_key)
      f.object.errors[placement_key]
    end
  end

  def react_type
    @react_type ||= options[:file_type].constantize.react_type
  end

  def render_fields
    if react_type == 'image'
      render('_image_fields')
    else
      render('_document_fields')
    end
  end

  def image(fp, class_name = '')
    if fp.object && fp.object.file
      url = fp.object.file.admin_thumb.url
      image_tag(url, class: "folio-console-thumbnail__img #{class_name}")
    end
  end

  def class_name
    base = ['folio-console-react-picker', 'folio-console-react-picker--single']
    base << 'folio-console-react-picker--error' if form_errors.present?
    base << 'f-c-js-atoms-placement-setting' if options[:atom_setting]
    base.join(' ')
  end

  def serialized_file(fp)
    Folio::Console::FileSerializer.new(fp.object.file)
                                  .serializable_hash[:data]
                                  .to_json
  end

  private
    def picked?
      placement = f.object.send(placement_key)
      return false if placement.blank?
      !placement.marked_for_destruction?
    end
end
