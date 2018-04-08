# frozen_string_literal: true

class Folio::Console::ReactImageSelectCell < FolioCell
  def show
    render
  end

  def f
    model
  end

  def title
    if options[:cover]
      if model.is_a?(Folio::Atom::Base)
        t('.title_single')
      else
        t('.title_cover')
      end
    else
      if options[:multi]
        t('.title_multi')
      else
        t('.title_single')
      end
    end
  end

  def images
    if options[:cover]
      f.object.cover_placement
    else
      f.object.file_placements.with_image
    end
  end

  def key
    if options[:cover]
      :cover_placement
    else
      :file_placements
    end
  end

  def exists
    if options[:cover]
      images.present?
    else
      images.exists?
    end
  end

  def html_safe_fields_for(&block)
    f.simple_fields_for key, images do |subfields|
      (yield subfields).html_safe
    end
  end
end
