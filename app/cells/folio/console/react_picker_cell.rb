# frozen_string_literal: true

class Folio::Console::ReactPickerCell < FolioCell
  def f
    model
  end

  def file_type_slug
    options[:file_type].demodulize.downcase
  end

  def placement_key
    options[:placement_key]
  end

  def title
    options[:title].presence ||
      f.object.class.human_attribute_name(placement_key)
  end

  # def single_nested?
  #   true
  # end

  # def has_one?
  #   true
  # end

  def form_errors
    if f.object.errors.include?(placement_key)
      f.object.errors[placement_key]
    end
  end

  def render_fields
    render("_#{file_type_slug}_fields")
  end

  # class='folio-console-react-file-select'
  # class=(options[:multi] ? 'folio-console-multi' : 'folio-console-single')
  # class=(exists ? 'folio-console-has-nested' : nil)
  # class=(form_errors ? 'text-danger has-danger' : nil)

  def image(fp)
    if fp.object && fp.object.file
      image_tag(fp.object
                  .file
                  .thumb(::Folio::FileSerializer::ADMIN_THUMBNAIL_SIZE)
                  .url)
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
      placement_key !~ /_placements/ ? true : nil
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
