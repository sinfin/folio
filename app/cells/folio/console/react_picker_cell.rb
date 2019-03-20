# frozen_string_literal: true

class Folio::Console::ReactPickerCell < Folio::ConsoleCell
  include ActionView::Helpers::NumberHelper

  def f
    model
  end

  def file_type_slug
    base = options[:file_type].demodulize.downcase
    single? ? base : base.pluralize
  end

  def placement_key
    options[:placement_key]
  end

  def placement_type
    f.object.class.reflect_on_association(placement_key).class_name
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

  def render_fields
    render("_#{file_type_slug}_fields")
  end

  def image(fp, class_name = '')
    if fp.object && fp.object.file
      url = fp.object
              .file
              .thumb(Folio::FileSerializer::ADMIN_THUMBNAIL_SIZE)
              .url
      image_tag(url, class: "folio-console-thumbnail__img #{class_name}")
    end
  end

  def class_name
    base = ['folio-console-react-picker']
    if single?
      base << 'folio-console-react-picker--single'
    else
      base << 'folio-console-react-picker--multi'
    end
    base << 'folio-console-react-picker--error' if form_errors.present?
    base.join(' ')
  end

  private

    def single?
      placement_key !~ /_placements/
    end

    def picked?
      placements = f.object.send(placement_key)
      return false if placements.blank?
      if single?
        !placements.marked_for_destruction?
      else
        placements.all? { |p| !p.marked_for_destruction? }
      end
    end
end
