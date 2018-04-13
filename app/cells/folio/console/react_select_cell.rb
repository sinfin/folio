# frozen_string_literal: true

class Folio::Console::ReactSelectCell < FolioCell
  BASE = nil

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

  def html_safe_fields_for(&block)
    f.simple_fields_for key, file_placements do |subfields|
      (yield subfields).html_safe
    end
  end

  def render_fields
    render(:fields)
  end
end
